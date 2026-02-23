import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showDeleteAlert: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isUploadingAvatar: Bool = false

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
            .background(FemColor.ivory.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(FemColor.pink)
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
            PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                ZStack {
                    // Decorative ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [FemColor.pink, FemColor.lightBlue, FemColor.green, FemColor.pink],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 96, height: 96)

                    AvatarView(
                        initials: appVM.currentUser?.initials ?? "?",
                        url: appVM.currentUser?.avatarURL,
                        size: 84
                    )

                    // Camera badge
                    Circle()
                        .fill(FemColor.pink)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if isUploadingAvatar {
                                ProgressView().tint(.white).scaleEffect(0.6)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                            }
                        }
                        .offset(x: 32, y: 32)
                }
            }
            .onChange(of: avatarPickerItem) { _, newItem in
                Task { await uploadAvatar(item: newItem) }
            }

            VStack(spacing: 4) {
                Text(appVM.currentUser?.fullName ?? "Member")
                    .font(FemFont.display(22))
                    .foregroundStyle(FemColor.darkBlue)

                Text(appVM.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.5))
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
                        .foregroundStyle(FemColor.darkBlue.opacity(0.4))

                    HStack(spacing: 8) {
                        Text(appVM.selectedHub?.name ?? "")
                            .font(.headline)
                            .foregroundStyle(FemColor.darkBlue)

                        StatusBadge(
                            text: appVM.isMembershipActive ? "Active" : "Inactive",
                            color: appVM.isMembershipActive ? FemColor.green : FemColor.orangeRed
                        )
                    }
                }

                Spacer()

                Circle()
                    .fill(FemColor.pink.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundStyle(FemColor.pink)
                    }
            }

            if let membership = appVM.membership {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Valid Until")
                            .font(.caption)
                            .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                        Text(membership.endDate.formatted(.dateTime.month(.wide).day().year()))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(FemColor.darkBlue)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Source")
                            .font(.caption)
                            .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                        Text(membership.source.rawValue.capitalized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(FemColor.darkBlue)
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
                .font(FemFont.title(18))
                .foregroundStyle(FemColor.darkBlue)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(appVM.hubs.filter(\.isActive)) { hub in
                        Button {
                            appVM.selectedHubId = hub.id
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(appVM.selectedHubId == hub.id ? FemColor.pink.opacity(0.12) : FemColor.ivory)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(appVM.selectedHubId == hub.id ? FemColor.pink : FemColor.darkBlue.opacity(0.3))
                                    }

                                Text(hub.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(appVM.selectedHubId == hub.id ? FemColor.darkBlue : FemColor.darkBlue.opacity(0.5))
                            }
                            .frame(width: 72)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var profileDetails: some View {
        VStack(spacing: 0) {
            if let user = appVM.currentUser {
                ProfileDetailRow(icon: "building.2", label: "Company", value: user.company)
                Divider().padding(.leading, 44)
                ProfileDetailRow(icon: "briefcase", label: "Job Title", value: user.jobTitle)
                Divider().padding(.leading, 44)
                ProfileDetailRow(icon: "graduationcap", label: "University", value: user.university)
                Divider().padding(.leading, 44)
                ProfileDetailRow(icon: "text.book.closed", label: "Degree", value: user.degree)
                if !user.phone.isEmpty {
                    Divider().padding(.leading, 44)
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
                .foregroundStyle(FemColor.darkBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.darkBlue.opacity(0.06))
                .clipShape(Capsule())
            }

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FemColor.orangeRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FemColor.orangeRed.opacity(0.06))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Avatar Upload

    private func uploadAvatar(item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingAvatar = true
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }

            // Compress to JPEG
            guard let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.7) else { return }

            let publicURL = try await SupabaseService.shared.uploadAvatar(imageData: jpeg)

            // Update the profile
            if var user = appVM.currentUser {
                user.avatarURL = URL(string: publicURL)
                appVM.currentUser = user
                try? await SupabaseService.shared.upsertProfile(user)
            }
        } catch {
            print("Avatar upload error: \(error)")
        }
        isUploadingAvatar = false
    }
}

private struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(FemColor.pink.opacity(0.08))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(FemColor.pink)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(FemColor.darkBlue)
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
                        .tint(FemColor.pink)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FemColor.ivory.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundStyle(FemColor.pink)
                    .fontWeight(.semibold)
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
        Task {
            try? await SupabaseService.shared.upsertProfile(user)
        }
    }
}
