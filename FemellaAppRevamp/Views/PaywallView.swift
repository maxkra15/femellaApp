import SwiftUI

struct PaywallView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isProcessing: Bool = false
    @State private var showCodeEntry: Bool = false
    @State private var membershipCode: String = ""
    @State private var codeError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.xxl) {
                    Spacer().frame(height: 20)

                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [FemColor.accentPink, FemColor.accentPinkDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )

                        Text("Join femella")
                            .font(.title.bold())
                            .foregroundStyle(FemColor.navy)

                        Text("Unlock access to exclusive events,\na vibrant community, and more")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let hub = appVM.selectedHub {
                        VStack(spacing: FemSpacing.lg) {
                            benefitRow(icon: "calendar.badge.clock", title: "Exclusive Events", description: "Connect, Learn, and Grow events curated for ambitious women")
                            benefitRow(icon: "person.3.fill", title: "Member Community", description: "Network with inspiring professionals across \(hub.name)")
                            benefitRow(icon: "star.circle.fill", title: "Priority Access", description: "First access to limited-capacity events and workshops")
                            benefitRow(icon: "globe.europe.africa.fill", title: "Multi-Hub Access", description: "Visit events in Zurich, London, Copenhagen, Berlin & Munich")
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Annual Membership")
                                    .font(.headline)
                                    .foregroundStyle(FemColor.navy)

                                Text(hub.membershipPriceFormatted)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(FemColor.accentPinkDark)

                                Text("per year · auto-renews")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, FemSpacing.xl)
                            .frame(maxWidth: .infinity)
                            .background(FemColor.accentPink.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 16))

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
                                    .foregroundStyle(FemColor.ctaBlue)
                            }

                            if showCodeEntry {
                                VStack(spacing: 12) {
                                    TextField("Enter code", text: $membershipCode)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .padding(14)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(.rect(cornerRadius: 12))

                                    if let error = codeError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(FemColor.danger)
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
                    }

                    Spacer().frame(height: FemSpacing.lg)
                }
                .padding(.horizontal, FemSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FemColor.blush.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sign Out") {
                        appVM.signOut()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(FemColor.accentPink)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FemColor.navy)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
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
