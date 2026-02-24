import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// APNs configuration
const APNS_KEY_ID = "2F939V52G2";
const APNS_TEAM_ID = "M8YUQQ98SK";
const APNS_BUNDLE_ID = "com.eigen.femella";
const APNS_KEY_PEM = `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQggIjXTE0X8y4A0aQe
sicN/MtQNtCIfWS+GF1zh7XUa9KgCgYIKoZIzj0DAQehRANCAAT+RclPez8iuBo0
LyUtrE1ZkZBfb9XdIVbZZdCI7vspV/vy5q7ILs89G9ZASsi9Cc042BtYf/x6/5LM
SgPy5Wxu
-----END PRIVATE KEY-----`;

// Use sandbox APNs for development/debugger devices
const APNS_HOST = "https://api.sandbox.push.apple.com"; 

async function createJWT(): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const now = Math.floor(Date.now() / 1000);
  const payload = { iss: APNS_TEAM_ID, iat: now };

  const enc = new TextEncoder();

  function b64url(data: Uint8Array): string {
    return btoa(String.fromCharCode(...data))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  }

  function strToB64url(str: string): string {
    return b64url(enc.encode(str));
  }

  const headerB64 = strToB64url(JSON.stringify(header));
  const payloadB64 = strToB64url(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  // Import the PEM private key
  const pemBody = APNS_KEY_PEM
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    enc.encode(signingInput)
  );

  const sigB64 = b64url(new Uint8Array(signature));
  return `${signingInput}.${sigB64}`;
}

async function sendPush(token: string, title: string, body: string, jwt: string): Promise<any> {
  const payload = {
    aps: {
      alert: { title, body: body.substring(0, 200) },
      sound: "default",
      badge: 1,
    }
  };

  const headers = {
    "authorization": `bearer ${jwt}`,
    "apns-topic": APNS_BUNDLE_ID,
    "apns-push-type": "alert",
    "apns-priority": "10",
    "apns-expiration": "0",
    "content-type": "application/json",
  };

  try {
    // Try production APNs first
    let res = await fetch(`https://api.push.apple.com/3/device/${token}`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload)
    });

    if (!res.ok) {
      let errBody = await res.text();
      // If token is for a sandbox environment, production APNs returns BadDeviceToken or BadEnvironmentKeyInToken
      if (
        (res.status === 400 && errBody.includes("BadDeviceToken")) ||
        (res.status === 403 && errBody.includes("BadEnvironmentKeyInToken"))
      ) {
        console.log(`Token ${token.substring(0, 8)}... seems to be a sandbox token. Falling back to sandbox APNs.`);
        res = await fetch(`https://api.sandbox.push.apple.com/3/device/${token}`, {
          method: "POST",
          headers,
          body: JSON.stringify(payload)
        });
        
        if (!res.ok) {
          errBody = await res.text();
          console.error(`Sandbox APNs Error for ${token.substring(0, 8)}...: ${res.status} ${errBody}`);
          return { success: false, error: `Sandbox ${res.status} ${errBody}`, token: token.substring(0, 8) };
        }
        return { success: true };
      }
      
      console.error(`Production APNs Error for ${token.substring(0, 8)}...: ${res.status} ${errBody}`);
      return { success: false, error: `Production ${res.status} ${errBody}`, token: token.substring(0, 8) };
    }
    return { success: true };
  } catch (e) {
    console.error(`Fetch Error for ${token.substring(0, 8)}...:`, e);
    return { success: false, error: String(e), token: token.substring(0, 8) };
  }
}

Deno.serve(async (req: Request) => {
  try {
    const { record } = await req.json();
    const userId = record.user_id;
    const title = record.title;
    const body = record.body || "";

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    const { data: tokens, error } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId)
      .eq("platform", "ios");

    if (error) {
      return new Response(JSON.stringify({ error: "Failed to fetch tokens" }), { status: 500 });
    }

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No tokens found for user" }), { status: 200 });
    }

    const jwt = await createJWT();

    const results = await Promise.all(
      tokens.map((t: { token: string }) => sendPush(t.token, title, body, jwt))
    );

    const sent = results.filter((r) => r.success).length;
    return new Response(
      JSON.stringify({ message: `Sent ${sent}/${tokens.length} pushes`, results }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
