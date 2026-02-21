import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)

                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(FemColor.accentPink)
                        .padding(.bottom, 4)

                    Text("femella")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(FemColor.navy)

                    Text("Empowering women through\nmeaningful connections")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 32)
                }

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(FemColor.danger)
                    }

                    Button {
                        Task { await handleAuth() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .femPrimaryButton(isEnabled: isFormValid)
                    }
                    .disabled(!isFormValid || isLoading)

                    Button {
                        withAnimation(.snappy) { isSignUp.toggle() }
                        errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .foregroundStyle(FemColor.navy)
                    }
                }
                .padding(.horizontal, FemSpacing.xl)

                Spacer().frame(height: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FemColor.blush.ignoresSafeArea())
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }

    private func handleAuth() async {
        isLoading = true
        errorMessage = nil
        if isSignUp {
            await appVM.signUp(email: email, password: password)
        } else {
            await appVM.signIn(email: email, password: password)
        }
        isLoading = false
    }
}
