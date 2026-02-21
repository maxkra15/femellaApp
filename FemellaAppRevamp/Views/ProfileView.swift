import SwiftUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showDeleteAlert: Bool = false
    @State private var showEditProfile: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.xl) {
                    profileHeader
                    membershipCard
                    hubSection
                    profileDetails
                    accountActions
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .background(FemColor.blush.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundStyle(FemColor.navy)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await appVM.deleteAccount() }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: FemSpacing.md) {
            AvatarView(
                initials: appVM.currentUser?.initials ?? "?",
                url: appVM.currentUser?.avatarURL,
                size: 80
            )

            VStack(spacing: 4) {
                Text(appVM.currentUser?.fullName ?? "Member")
                    .font(.title2.bold())
                    .foregroundStyle(FemColor.navy)

                Text(appVM.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FemSpacing.lg)
    }

    private var membershipCard: some View {
        VStack(spacing: FemSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Membership")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text(appVM.selectedHub?.name ?? "")
                            .font(.headline)
                            .foregroundStyle(FemColor.navy)

                        StatusBadge(
                            text: appVM.isMembershipActive ? "Active" : "Inactive",
                            color: appVM.isMembershipActive ? FemColor.success : FemColor.danger
                        )
                    }
                }

                Spacer()

                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(FemColor.accentPink)
            }

            if let membership = appVM.membership {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Valid Until")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(membership.endDate.formatted(.dateTime.month(.wide).day().year()))
                            .font(.subheadline.weight(.medium))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Source")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(membership.source.rawValue.capitalized)
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .padding(FemSpacing.lg)
        .femCard()
    }

    private var hubSection: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            Text("Visit Another Hub")
                .font(.headline)
                .foregroundStyle(FemColor.navy)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(appVM.hubs.filter(\.isActive)) { hub in
                        Button {
                            appVM.selectedHubId = hub.id
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(appVM.selectedHubId == hub.id ? FemColor.accentPink : .secondary)

                                Text(hub.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(appVM.selectedHubId == hub.id ? FemColor.navy : .secondary)
                            }
                            .frame(width: 72)
                            .padding(.vertical, 12)
                            .background(appVM.selectedHubId == hub.id ? FemColor.accentPink.opacity(0.08) : Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 14))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var profileDetails: some View {
        VStack(spacing: FemSpacing.sm) {
            if let user = appVM.currentUser {
                ProfileDetailRow(icon: "building.2", label: "Company", value: user.company)
                ProfileDetailRow(icon: "briefcase", label: "Job Title", value: user.jobTitle)
                ProfileDetailRow(icon: "graduationcap", label: "University", value: user.university)
                ProfileDetailRow(icon: "text.book.closed", label: "Degree", value: user.degree)
                if !user.phone.isEmpty {
                    ProfileDetailRow(icon: "phone", label: "Phone", value: user.phone)
                }
            }
        }
        .padding(FemSpacing.lg)
        .femCard()
    }

    private var accountActions: some View {
        VStack(spacing: FemSpacing.md) {
            Button {
                appVM.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FemColor.navy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 14))
            }

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FemColor.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.danger.opacity(0.06))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }
}

private struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(FemColor.accentPink)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct EditProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var company: String = ""
    @State private var jobTitle: String = ""
    @State private var showProfile: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone", text: $phone)
                }
                Section("Professional") {
                    TextField("Company", text: $company)
                    TextField("Job Title", text: $jobTitle)
                }
                Section("Privacy") {
                    Toggle("Show Profile to Members", isOn: $showProfile)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let user = appVM.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    phone = user.phone
                    company = user.company
                    jobTitle = user.jobTitle
                    showProfile = user.showProfileToMembers
                }
            }
        }
    }

    private func saveProfile() {
        guard var user = appVM.currentUser else { return }
        user.firstName = firstName
        user.lastName = lastName
        user.phone = phone
        user.company = company
        user.jobTitle = jobTitle
        user.showProfileToMembers = showProfile
        appVM.currentUser = user
    }
}
