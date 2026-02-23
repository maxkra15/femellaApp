import SwiftUI

struct PaywallView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isProcessing: Bool = false
    @State private var showCodeEntry: Bool = false
    @State private var membershipCode: String = ""
    @State private var codeError: String?
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                FemColor.ivory.ignoresSafeArea()

                // Decorative pattern
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(FemColor.darkBlue)
                            .frame(width: geo.size.width * 1.4)
                            .offset(x: -geo.size.width * 0.2, y: -geo.size.width * 0.85)

                        Circle()
                            .fill(FemColor.pink.opacity(0.15))
                            .frame(width: geo.size.width * 0.6)
                            .offset(x: geo.size.width * 0.55, y: -geo.size.width * 0.15)
                    }
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FemSpacing.xxl) {
                        // Hero
                        VStack(spacing: 16) {
                            Spacer().frame(height: 40)

                            ZStack {
                                Circle()
                                    .fill(FemColor.pink.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white)
                            }
                            .scaleEffect(appeared ? 1 : 0.7)
                            .opacity(appeared ? 1 : 0)

                                Text("Join femella")
                                .font(FemFont.display(34))
                                .foregroundStyle(FemColor.darkBlue)
                                .opacity(appeared ? 1 : 0)

                            Text("Unlock access to exclusive events,\na vibrant community, and more")
                                .font(.subheadline)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)

                            Spacer().frame(height: 16)
                        }

                        if let hub = appVM.selectedHub {
                            // Benefits
                            VStack(spacing: 0) {
                                benefitRow(icon: "calendar.badge.clock", title: "Exclusive Events", description: "Connect, Learn, and Grow events curated for ambitious women", color: FemColor.pink)
                                Divider().padding(.horizontal, FemSpacing.lg)
                                benefitRow(icon: "person.3.fill", title: "Member Community", description: "Network with inspiring professionals across \(hub.name)", color: FemColor.green)
                                Divider().padding(.horizontal, FemSpacing.lg)
                                benefitRow(icon: "star.circle.fill", title: "Priority Access", description: "First access to limited-capacity events and workshops", color: FemColor.lightBlue)
                                Divider().padding(.horizontal, FemSpacing.lg)
                                benefitRow(icon: "globe.europe.africa.fill", title: "Multi-Hub Access", description: "Visit events in Zurich, London, Copenhagen, Berlin & Munich", color: FemColor.darkBlue)
                            }
                            .padding(.vertical, 6)
                            .background(FemColor.cardBackground)
                            .clipShape(.rect(cornerRadius: 20))
                            .shadow(color: FemColor.darkBlue.opacity(0.06), radius: 12, y: 6)
                            .padding(.horizontal, FemSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                            // Price card
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("Annual Membership")
                                        .font(FemFont.title(18))
                                        .foregroundStyle(FemColor.darkBlue)

                                    Text(hub.membershipPriceFormatted)
                                        .font(FemFont.display(36))
                                        .foregroundStyle(FemColor.pink)

                                    Text("per year · auto-renews")
                                        .font(.caption)
                                        .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                                }
                                .padding(.vertical, FemSpacing.xl)
                                .frame(maxWidth: .infinity)
                                .background(FemColor.ivory)
                                .clipShape(.rect(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(FemColor.pink.opacity(0.2), lineWidth: 1)
                                )

                                Button {
                                    Task { await subscribe() }
                                } label: {
                                    Group {
                                        if isProcessing {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Subscribe Now")
                                        }
                                    }
                                    .femPrimaryButton(isEnabled: !isProcessing)
                                }
                                .disabled(isProcessing)

                                Button {
                                    withAnimation(.snappy) { showCodeEntry.toggle() }
                                } label: {
                                    Text("Have a membership code?")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(FemColor.lightBlue)
                                }

                                if showCodeEntry {
                                    VStack(spacing: 12) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "ticket")
                                                .foregroundStyle(FemColor.pink)
                                            TextField("Enter code", text: $membershipCode)
                                                .textInputAutocapitalization(.never)
                                                .autocorrectionDisabled()
                                        }
                                        .padding(14)
                                        .background(FemColor.ivory)
                                        .clipShape(.rect(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
                                        )

                                        if let error = codeError {
                                            Text(error)
                                                .font(.caption)
                                                .foregroundStyle(FemColor.orangeRed)
                                        }

                                        Button {
                                            Task { await redeemCode() }
                                        } label: {
                                            Text("Redeem Code")
                                                .femSecondaryButton()
                                        }
                                        .disabled(membershipCode.isEmpty || isProcessing)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.horizontal, FemSpacing.xl)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        }

                        Spacer().frame(height: FemSpacing.lg)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FemColor.darkBlue)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, FemSpacing.lg)
        .padding(.vertical, FemSpacing.md)
    }

    private func subscribe() async {
        isProcessing = true
        await appVM.activateMembership()
        isProcessing = false
    }

    private func redeemCode() async {
        isProcessing = true
        codeError = nil
        let success = await appVM.redeemCode(membershipCode)
        if !success {
            codeError = "Invalid or expired membership code"
        }
        isProcessing = false
    }
}
