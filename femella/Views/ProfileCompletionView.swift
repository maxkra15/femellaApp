import SwiftUI
import PhotosUI

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
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isUploadingAvatar: Bool = false

    private let totalSteps = 3
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            ZStack {
                FemColor.ivory.ignoresSafeArea()

                // Decorative
                GeometryReader { geo in
                    Circle()
                        .fill(FemColor.pink.opacity(0.05))
                        .frame(width: geo.size.width * 0.7)
                        .offset(x: geo.size.width * 0.5, y: -geo.size.width * 0.15)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FemSpacing.xl) {
                        // Header
                        VStack(spacing: 12) {
                            FemLogo(size: 56, style: .pink)

                            Text("Complete Your Profile")
                                .font(FemFont.display(26))
                                .foregroundStyle(FemColor.darkBlue)

                            Text("Tell us about yourself to get started")
                                .font(.subheadline)
                                .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        }
                        .padding(.top, FemSpacing.xl)

                        // Avatar Picker
                        let currentUser = appVM.currentUser
                        PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(FemColor.ivory)
                                    .frame(width: 104, height: 104)
                                    .shadow(color: FemColor.darkBlue.opacity(0.06), radius: 10, y: 5)

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

                        // Progress dots
                        HStack(spacing: 8) {
                            ForEach(0..<totalSteps, id: \.self) { step in
                                Capsule()
                                    .fill(step <= currentStep ? FemColor.pink : FemColor.darkBlue.opacity(0.1))
                                    .frame(width: step == currentStep ? 32 : 10, height: 6)
                                    .animation(.snappy, value: currentStep)
                            }
                        }

                        // Personal
                        formSection(title: "Personal", icon: "person.fill") {
                            HStack(spacing: 12) {
                                styledField("First Name", text: $firstName)
                                    .onChange(of: firstName) { _, _ in updateStep() }
                                styledField("Last Name", text: $lastName)
                                    .onChange(of: lastName) { _, _ in updateStep() }
                            }
                            styledField("Phone (optional)", text: $phone)
                                .keyboardType(.phonePad)
                        }

                        // Education
                        formSection(title: "Education", icon: "graduationcap.fill") {
                            styledField("University", text: $university)
                                .onChange(of: university) { _, _ in updateStep() }
                            styledField("Degree", text: $degree)
                        }

                        // Professional
                        formSection(title: "Professional", icon: "briefcase.fill") {
                            styledField("Company", text: $company)
                                .onChange(of: company) { _, _ in updateStep() }
                            styledField("Job Title", text: $jobTitle)
                        }

                        // Home Hub
                        formSection(title: "Home Hub", icon: "mappin.circle.fill") {
                            VStack(spacing: 8) {
                                ForEach(appVM.hubs.filter(\.isActive)) { hub in
                                    Button {
                                        withAnimation(.snappy) {
                                            selectedHubId = hub.id
                                            updateStep()
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(hub.name)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(FemColor.darkBlue)
                                                Text(hub.country)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Circle()
                                                .strokeBorder(selectedHubId == hub.id ? FemColor.pink : FemColor.darkBlue.opacity(0.15), lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                                .overlay {
                                                    if selectedHubId == hub.id {
                                                        Circle()
                                                            .fill(FemColor.pink)
                                                            .frame(width: 12, height: 12)
                                                            .transition(.scale)
                                                    }
                                                }
                                        }
                                        .padding(14)
                                        .background(selectedHubId == hub.id ? FemColor.pink.opacity(0.06) : FemColor.ivory)
                                        .clipShape(.rect(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(selectedHubId == hub.id ? FemColor.pink.opacity(0.3) : FemColor.darkBlue.opacity(0.06), lineWidth: 1)
                                        )
                                    }
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
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Handlers

    private func uploadAvatar(item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingAvatar = true
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.7) else { return }

            let publicURL = try await SupabaseService.shared.uploadAvatar(imageData: jpeg)

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

    @ViewBuilder
    private func formSection(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(FemColor.pink)
                Text(title)
                    .font(FemFont.title(18))
                    .foregroundStyle(FemColor.darkBlue)
            }
            content()
        }
        .padding(FemSpacing.lg)
        .background(FemColor.cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: FemColor.darkBlue.opacity(0.04), radius: 8, y: 4)
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(14)
            .background(FemColor.ivory)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(FemColor.darkBlue.opacity(0.06), lineWidth: 1)
            )
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !university.isEmpty &&
        !company.isEmpty && !jobTitle.isEmpty && !selectedHubId.isEmpty
    }

    private func updateStep() {
        if !firstName.isEmpty && !lastName.isEmpty {
            if !university.isEmpty {
                if !company.isEmpty && !selectedHubId.isEmpty {
                    currentStep = 2
                } else {
                    currentStep = 1
                }
            } else {
                currentStep = 0
            }
        } else {
            currentStep = 0
        }
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
