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
                    profileDetails
                    accountActions
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .background(FemColor.ivoryBlueWash.ignoresSafeArea())
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
            let currentUser = appVM.currentUser
            PhotosPicker(selection: $avatarPickerItem, matching: .images, photoLibrary: .shared()) {
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
                        initials: currentUser?.initials ?? "?",
                        url: currentUser?.avatarURL,
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
                Task { @MainActor in await self.uploadAvatar(item: newItem) }
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
                        if let hubId = appVM.membership?.hubId ?? appVM.currentUser?.homeHubId,
                           let homeHub = appVM.hubs.first(where: { $0.id == hubId }) {
                            Text(homeHub.name)
                                .font(.headline)
                                .foregroundStyle(FemColor.darkBlue)
                        }

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

    // MARK: - removed hub section

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
                if let bday = user.birthday {
                    Divider().padding(.leading, 44)
                    ProfileDetailRow(icon: "gift", label: "Birthday", value: bday.formatted(.dateTime.day().month().year()))
                }
                if let ln = user.linkedinUrl, !ln.isEmpty {
                    Divider().padding(.leading, 44)
                    ProfileDetailRow(icon: "link", label: "LinkedIn", value: ln)
                }
                if let fun = user.funFacts, !fun.isEmpty {
                    Divider().padding(.leading, 44)
                    ProfileDetailRow(icon: "star", label: "Fun Facts", value: fun)
                }
                if let hobbies = user.hobbies, !hobbies.isEmpty {
                    Divider().padding(.leading, 44)
                    ProfileDetailRow(icon: "heart", label: "Hobbies", value: hobbies)
                }
                if user.likesSports {
                    Divider().padding(.leading, 44)
                    ProfileDetailRow(icon: "figure.run", label: "Sports", value: "Likes Sports" + (user.interestedInRunningClub ? ", Running Club" : "") + (user.interestedInCyclingClub ? ", Cycling Club" : ""))
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
        defer {
            isUploadingAvatar = false
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }

            // Compress to JPEG
            guard let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.7) else { return }

            try await appVM.updateAvatar(imageData: jpeg)
        } catch {
            print("Avatar upload error: \(error)")
        }
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
    @State private var linkedinUrl: String = ""
    @State private var funFacts: String = ""
    @State private var hobbies: String = ""
    @State private var includeBirthday: Bool = false
    @State private var birthday: Date = Date()
    @State private var likesSports: Bool = false
    @State private var interestedInRunningClub: Bool = false
    @State private var interestedInCyclingClub: Bool = false
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isUploadingAvatar: Bool = false

    private enum Field: Hashable {
        case firstName, lastName, phone, company, jobTitle, linkedin, funFacts, hobbies
    }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            VStack {
                // Avatar Picker Header
                let currentUser = appVM.currentUser
                PhotosPicker(selection: $avatarPickerItem, matching: .images, photoLibrary: .shared()) {
                    ZStack {
                        Circle()
                            .strokeBorder(FemColor.darkBlue.opacity(0.1), lineWidth: 1)
                            .frame(width: 104, height: 104)

                        AvatarView(
                            initials: currentUser?.initials ?? "?",
                            url: currentUser?.avatarURL,
                            size: 96
                        )

                        Circle()
                            .fill(FemColor.pink)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if isUploadingAvatar {
                                    ProgressView().tint(.white).scaleEffect(0.6)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                }
                            }
                            .offset(x: 36, y: 36)
                    }
                }
                .onChange(of: avatarPickerItem) { _, newItem in
                    Task { @MainActor in await self.uploadAvatar(item: newItem) }
                }
                .padding(.top, FemSpacing.xl)

                Form {
                    Section("Personal") {
                        TextField("First Name", text: $firstName)
                            .focused($focusedField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .lastName }
                        TextField("Last Name", text: $lastName)
                            .focused($focusedField, equals: .lastName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .phone }
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .focused($focusedField, equals: .phone)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .company }
                    }
                    Section("Professional") {
                        TextField("Company", text: $company)
                            .focused($focusedField, equals: .company)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .jobTitle }
                        TextField("Job Title", text: $jobTitle)
                            .focused($focusedField, equals: .jobTitle)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .linkedin }
                        TextField("LinkedIn URL", text: $linkedinUrl)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .linkedin)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .funFacts }
                    }
                    Section("About You") {
                        Toggle("Include Birthday", isOn: $includeBirthday)
                        if includeBirthday {
                            DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                        }
                        TextField("Fun Facts", text: $funFacts)
                            .focused($focusedField, equals: .funFacts)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .hobbies }
                        TextField("Hobbies", text: $hobbies)
                            .focused($focusedField, equals: .hobbies)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                    }
                Section("Interests") {
                    Toggle("Do you like sports?", isOn: $likesSports)
                    if likesSports {
                        Toggle("Interested in Running Club?", isOn: $interestedInRunningClub)
                        Toggle("Interested in Cycling Club?", isOn: $interestedInCyclingClub)
                    }
                }
                Section("Privacy") {
                    Toggle("Show Profile to Members", isOn: $showProfile)
                        .tint(FemColor.pink)
                }
                }
                .scrollContentBackground(.hidden)
            }
            .background(FemColor.ivoryBlueWash.ignoresSafeArea())
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
                    linkedinUrl = user.linkedinUrl ?? ""
                    if let bday = user.birthday {
                        includeBirthday = true
                        birthday = bday
                    }
                    funFacts = user.funFacts ?? ""
                    hobbies = user.hobbies ?? ""
                    likesSports = user.likesSports
                    interestedInRunningClub = user.interestedInRunningClub
                    interestedInCyclingClub = user.interestedInCyclingClub
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
        user.linkedinUrl = linkedinUrl.isEmpty ? nil : linkedinUrl
        user.birthday = includeBirthday ? birthday : nil
        user.funFacts = funFacts.isEmpty ? nil : funFacts
        user.hobbies = hobbies.isEmpty ? nil : hobbies
        user.likesSports = likesSports
        user.interestedInRunningClub = interestedInRunningClub
        user.interestedInCyclingClub = interestedInCyclingClub
        appVM.currentUser = user
        Task {
            do {
                try await SupabaseService.shared.upsertProfile(user)
            } catch {
                print("Profile save error: \(error)")
            }
        }
    }

    private func uploadAvatar(item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingAvatar = true
        defer {
            isUploadingAvatar = false
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.7) else { return }

            try await appVM.updateAvatar(imageData: jpeg)
        } catch {
            print("Avatar upload error: \(error)")
        }
    }
}
