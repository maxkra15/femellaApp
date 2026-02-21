import SwiftUI

struct ProfileCompletionView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var university: String = ""
    @State private var degree: String = ""
    @State private var company: String = ""
    @State private var jobTitle: String = ""
    @State private var selectedHubId: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.xl) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(FemColor.accentPink)

                        Text("Complete Your Profile")
                            .font(.title2.bold())
                            .foregroundStyle(FemColor.navy)

                        Text("Tell us about yourself to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, FemSpacing.lg)

                    VStack(spacing: FemSpacing.md) {
                        SectionHeader(title: "Personal")

                        HStack(spacing: 12) {
                            FormField(placeholder: "First Name", text: $firstName)
                            FormField(placeholder: "Last Name", text: $lastName)
                        }

                        FormField(placeholder: "Phone (optional)", text: $phone)
                            .keyboardType(.phonePad)
                    }

                    VStack(spacing: FemSpacing.md) {
                        SectionHeader(title: "Education")
                        FormField(placeholder: "University", text: $university)
                        FormField(placeholder: "Degree", text: $degree)
                    }

                    VStack(spacing: FemSpacing.md) {
                        SectionHeader(title: "Professional")
                        FormField(placeholder: "Company", text: $company)
                        FormField(placeholder: "Job Title", text: $jobTitle)
                    }

                    VStack(spacing: FemSpacing.md) {
                        SectionHeader(title: "Home Hub")

                        VStack(spacing: 8) {
                            ForEach(MockDataService.hubs.filter(\.isActive)) { hub in
                                Button {
                                    selectedHubId = hub.id
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(hub.name)
                                                .font(.body.weight(.medium))
                                            Text(hub.country)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedHubId == hub.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(FemColor.accentPink)
                                        }
                                    }
                                    .padding(14)
                                    .background(selectedHubId == hub.id ? FemColor.accentPink.opacity(0.08) : Color(.secondarySystemBackground))
                                    .clipShape(.rect(cornerRadius: 12))
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }

                    Button {
                        Task { await saveProfile() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue")
                            }
                        }
                        .femPrimaryButton(isEnabled: isFormValid)
                    }
                    .disabled(!isFormValid || isLoading)

                    Spacer().frame(height: FemSpacing.lg)
                }
                .padding(.horizontal, FemSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FemColor.blush.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !university.isEmpty &&
        !company.isEmpty && !jobTitle.isEmpty && !selectedHubId.isEmpty
    }

    private func saveProfile() async {
        guard let user = appVM.currentUser else { return }
        isLoading = true
        let profile = UserProfile(
            id: user.id,
            firstName: firstName,
            lastName: lastName,
            email: user.email,
            phone: phone,
            university: university,
            degree: degree,
            company: company,
            jobTitle: jobTitle,
            homeHubId: selectedHubId,
            avatarURL: nil,
            showProfileToMembers: true
        )
        await appVM.completeProfile(profile)
        isLoading = false
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(FemColor.navy)
            Spacer()
        }
    }
}

private struct FormField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
    }
}
