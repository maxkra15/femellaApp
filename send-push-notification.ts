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

type APNSResult = {
  token: string
  endpoint: "production" | "sandbox" | "request"
  status: number
  success: boolean
  body?: string
  error?: string
}

const ALLOWED_ORIGINS = new Set([
  "https://femella-admin.vercel.app",
  "http://localhost:3000",
  "http://127.0.0.1:3000",
]);

function buildCorsHeaders(origin: string | null): HeadersInit {
  const allowOrigin = origin && ALLOWED_ORIGINS.has(origin)
    ? origin
    : "https://femella-admin.vercel.app";

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function jsonResponse(body: unknown, init: ResponseInit = {}, origin: string | null = null): Response {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...buildCorsHeaders(origin),
      ...(init.headers ?? {}),
    },
  });
}

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

function shortToken(token: string): string {
  return `${token.slice(0, 8)}...`
}

async function sendPush(token: string, title: string, body: string, jwt: string): Promise<APNSResult> {
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

  const tokenPreview = shortToken(token)
  const payloadBody = JSON.stringify(payload)

  const postPush = async (endpoint: "production" | "sandbox") => {
    const url = endpoint === "production"
      ? `https://api.push.apple.com/3/device/${token}`
      : `https://api.sandbox.push.apple.com/3/device/${token}`

    const res = await fetch(url, {
      method: "POST",
      headers,
      body: payloadBody
    })
    const rawBody = await res.text()
    return { endpoint, status: res.status, body: rawBody, ok: res.ok }
  }

  try {
    const production = await postPush("production")

    if (production.ok) {
      console.log(`[APNS] token=${tokenPreview} environment=production status=${production.status}`)
      return {
        token: tokenPreview,
        endpoint: "production",
        status: production.status,
        success: true,
        body: production.body || "ok"
      }
    }

    const errorMessage = `Production ${production.status} ${production.body}`
    console.error(`[APNS] token=${tokenPreview} environment=production status=${production.status} body=${production.body}`)

    if (
      (production.status === 400 && production.body.includes("BadDeviceToken")) ||
      (production.status === 403 && production.body.includes("BadEnvironmentKeyInToken"))
    ) {
      console.log(`[APNS] token=${tokenPreview} switching to sandbox environment`)
      const sandbox = await postPush("sandbox")

      if (sandbox.ok) {
        console.log(`[APNS] token=${tokenPreview} environment=sandbox status=${sandbox.status}`)
        return {
          token: tokenPreview,
          endpoint: "sandbox",
          status: sandbox.status,
          success: true,
          body: sandbox.body || "ok"
        }
      }

      console.error(`[APNS] token=${tokenPreview} environment=sandbox status=${sandbox.status} body=${sandbox.body}`)
      return {
        token: tokenPreview,
        endpoint: "sandbox",
        status: sandbox.status,
        success: false,
        error: `Sandbox ${sandbox.status} ${sandbox.body}`
      }
    }

    return {
      token: tokenPreview,
      endpoint: "production",
      status: production.status,
      success: false,
      error: errorMessage
    }
  } catch (e) {
    console.error(`[APNS] token=${tokenPreview} request error:`, e)
    return {
      token: tokenPreview,
      endpoint: "request",
      status: 0,
      success: false,
      error: String(e)
    }
  }
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: buildCorsHeaders(origin),
    });
  }

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
      return jsonResponse({ error: "Failed to fetch tokens" }, { status: 500 }, origin);
    }

    if (!tokens || tokens.length === 0) {
      return jsonResponse({ message: "No tokens found for user" }, { status: 200 }, origin);
    }

    const jwt = await createJWT();

    const results = await Promise.all(
      tokens.map((t: { token: string }) => sendPush(t.token, title, body, jwt))
    );

    const sent = results.filter((r) => r.success).length;
    console.log(`[send-push-notification] user=${userId} title="${title}" sent=${sent}/${results.length}`)
    console.log(`[send-push-notification] apns results: ${JSON.stringify(results)}`)
    return jsonResponse(
      { message: `Sent ${sent}/${tokens.length} pushes`, results },
      { status: 200 },
      origin,
    );
  } catch (e) {
    return jsonResponse({ error: String(e) }, { status: 500 }, origin);
  }
});
