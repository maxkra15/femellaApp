import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var appeared: Bool = false

    private enum Field {
        case email
        case password
    }
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            // Background
            FemColor.ivory.ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                CirclePattern(size: geo.size.width * 0.9, opacity: 0.07)
                    .offset(x: geo.size.width * 0.5, y: -geo.size.width * 0.15)

                Circle()
                    .fill(FemColor.pink.opacity(0.04))
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero section
                    VStack(spacing: 16) {
                        Spacer().frame(height: 60)

                        FemLogo(size: 72, style: .pink)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .opacity(appeared ? 1 : 0)

                        VStack(spacing: 6) {
                            Text("femella")
                                .font(FemFont.display(40))
                                .foregroundStyle(FemColor.darkBlue)

                            Text("Empowering women through\nmeaningful connections")
                                .font(.subheadline)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                        Spacer().frame(height: 24)
                    }

                    // Form card
                    VStack(spacing: 20) {
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(FemFont.title(22))
                            .foregroundStyle(FemColor.darkBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(FemColor.pink)
                                    .frame(width: 20)
                                TextField("Email address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            .padding(14)
                            .background(FemColor.ivory)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
                            )

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundStyle(FemColor.pink)
                                    .frame(width: 20)
                                SecureField("Password", text: $password)
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                        if isFormValid {
                                            Task { await handleAuth() }
                                        }
                                    }
                            }
                            .padding(14)
                            .background(FemColor.ivory)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
                            )
                        }

                        if let error = errorMessage ?? appVM.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(FemColor.orangeRed)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(FemColor.orangeRed)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FemColor.orangeRed.opacity(0.08))
                            .clipShape(.rect(cornerRadius: 10))
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

                        // Divider
                        HStack {
                            Rectangle().fill(FemColor.darkBlue.opacity(0.08)).frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.3))
                            Rectangle().fill(FemColor.darkBlue.opacity(0.08)).frame(height: 1)
                        }

                        Button {
                            withAnimation(.snappy) {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                                .font(.subheadline)
                                .foregroundStyle(FemColor.darkBlue)
                        }
                    }
                    .padding(FemSpacing.xl)
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 24))
                    .shadow(color: FemColor.darkBlue.opacity(0.06), radius: 16, y: 8)
                    .padding(.horizontal, FemSpacing.lg)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                appeared = true
            }
        }
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
