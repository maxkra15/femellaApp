import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> AuthUser {
        let response = try await client.auth.signIn(email: email, password: password)
        return AuthUser(id: response.user.id.uuidString, email: response.user.email ?? "")
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        let response = try await client.auth.signUp(email: email, password: password)
        return AuthUser(id: response.user.id.uuidString, email: response.user.email ?? "")
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        // Delete the profile (cascade will clean up related data)
        if let userId = currentUserId {
            try await client.from("profiles").delete().eq("id", value: userId).execute()
        }
        try await client.auth.signOut()
    }

    func restoreSession() async -> AuthUser? {
        do {
            let session = try await client.auth.session
            if session.isExpired {
                return nil
            }
            return AuthUser(id: session.user.id.uuidString, email: session.user.email ?? "")
        } catch {
            return nil
        }
    }

    var currentUserId: String? {
        client.auth.currentSession?.user.id.uuidString
    }

    // MARK: - Device Tokens (Push Notifications)

    func upsertDeviceToken(_ token: String) async throws {
        guard let userId = currentUserId else { return }
        struct TokenRow: Encodable {
            let user_id: String
            let token: String
            let platform: String
        }
        try await client.from("device_tokens")
            .upsert(TokenRow(user_id: userId, token: token, platform: "ios"), onConflict: "user_id,token")
            .execute()
    }

    func removeDeviceToken(_ token: String) async throws {
        guard let userId = currentUserId else { return }
        try await client.from("device_tokens")
            .delete()
            .eq("user_id", value: userId)
            .eq("token", value: token)
            .execute()
    }

    // MARK: - Storage

    func uploadAvatar(imageData: Data) async throws -> String {
        guard let userId = currentUserId else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]) }
        let path = "avatars/\(userId)/avatar.jpg"

        // Upload (upsert: overwrite if exists)
        try await client.storage.from("images").upload(
            path,
            data: imageData,
            options: .init(contentType: "image/jpeg", upsert: true)
        )

        // Get the public URL
        let publicURL = try client.storage.from("images").getPublicURL(path: path)
        return publicURL.absoluteString
    }

    /// Build the public URL for an event hero image stored in images/events/{event_id}.jpg
    func eventImageURL(for eventId: String) -> URL? {
        try? client.storage.from("images").getPublicURL(path: "events/\(eventId).jpg")
    }

    // MARK: - Profiles

    func fetchProfile(userId: String) async throws -> UserProfile? {
        let rows: [ProfileRow] = try await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        return rows.first.map { $0.toUserProfile() }
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        let row = ProfileRow.from(profile)
        try await client.from("profiles")
            .upsert(row)
            .execute()
    }

    // MARK: - Hubs

    func fetchHubs() async throws -> [Hub] {
        let rows: [HubRow] = try await client.from("hubs")
            .select()
            .eq("is_active", value: true)
            .order("name")
            .execute()
            .value
        return rows.map { $0.toHub() }
    }

    // MARK: - Memberships

    func fetchMembership(userId: String) async throws -> Membership? {
        let rows: [MembershipRow] = try await client.from("memberships")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first.map { $0.toMembership() }
    }

    func createMembership(userId: String, hubId: String, source: String) async throws -> Membership {
        let row = MembershipInsert(
            userId: userId,
            hubId: hubId,
            status: "active",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            source: source
        )
        let result: [MembershipRow] = try await client.from("memberships")
            .insert(row)
            .select()
            .execute()
            .value
        return result[0].toMembership()
    }

    // MARK: - Events

    func fetchEvents(hubId: String) async throws -> [Event] {
        let rows: [EventRow] = try await client.from("events")
            .select()
            .eq("hub_id", value: hubId)
            .order("starts_at")
            .execute()
            .value
        return rows.map { $0.toEvent() }
    }

    // MARK: - Event Registrations

    func fetchRegistrations(userId: String) async throws -> [EventRegistration] {
        let rows: [EventRegistrationRow] = try await client.from("event_registrations")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return rows.map { $0.toEventRegistration() }
    }

    func registerForEvent(eventId: String, userId: String, status: String) async throws -> EventRegistration {
        let row = EventRegistrationInsert(
            eventId: eventId,
            userId: userId,
            status: status,
            position: status == "waitlisted" ? 1 : nil
        )
        let result: [EventRegistrationRow] = try await client.from("event_registrations")
            .insert(row)
            .select()
            .execute()
            .value
        return result[0].toEventRegistration()
    }

    func deregisterFromEvent(registrationId: String) async throws {
        try await client.from("event_registrations")
            .update(["status": "canceled", "canceled_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: registrationId)
            .execute()
    }

    // MARK: - Notifications

    func fetchNotifications(userId: String) async throws -> [AppNotification] {
        let rows: [NotificationDBRow] = try await client.from("notifications")
            .select()
            .eq("user_id", value: userId)
            .order("sent_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toNotification() }
    }

    func markNotificationRead(id: String) async throws {
        try await client.from("notifications")
            .update(["is_read": true])
            .eq("id", value: id)
            .execute()
    }

    func markAllNotificationsRead(userId: String) async throws {
        try await client.from("notifications")
            .update(["is_read": true])
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }

    // MARK: - Surveys

    func fetchSurveys(hubId: String) async throws -> [Survey] {
        let rows: [SurveyRow] = try await client.from("surveys")
            .select("*, survey_questions(*)")
            .eq("hub_id", value: hubId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toSurvey() }
    }

    func fetchCompletedSurveyIds(userId: String) async throws -> Set<String> {
        let rows: [SurveyResponseRow] = try await client.from("survey_responses")
            .select("question_id")
            .eq("user_id", value: userId)
            .execute()
            .value
        // Get unique survey IDs that the user has responded to
        return Set(rows.map { $0.questionId })
    }

    func submitSurveyResponses(userId: String, surveyId: String, answers: [String: String]) async throws {
        var inserts: [SurveyResponseInsert] = []
        for (questionId, answer) in answers {
            inserts.append(SurveyResponseInsert(questionId: questionId, userId: userId, answer: answer))
        }
        try await client.from("survey_responses")
            .upsert(inserts)
            .execute()
    }
}

// MARK: - Auth Helper
struct AuthUser {
    let id: String
    let email: String
}

// MARK: - Database Row Types (snake_case mapping)

struct ProfileRow: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let university: String
    let degree: String
    let company: String
    let jobTitle: String
    let homeHubId: String
    let avatarUrl: String?
    let showProfileToMembers: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case university
        case degree
        case company
        case jobTitle = "job_title"
        case homeHubId = "home_hub_id"
        case avatarUrl = "avatar_url"
        case showProfileToMembers = "show_profile_to_members"
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            university: university,
            degree: degree,
            company: company,
            jobTitle: jobTitle,
            homeHubId: homeHubId,
            avatarURL: avatarUrl.flatMap { URL(string: $0) },
            showProfileToMembers: showProfileToMembers
        )
    }

    static func from(_ profile: UserProfile) -> ProfileRow {
        ProfileRow(
            id: profile.id,
            firstName: profile.firstName,
            lastName: profile.lastName,
            email: profile.email,
            phone: profile.phone,
            university: profile.university,
            degree: profile.degree,
            company: profile.company,
            jobTitle: profile.jobTitle,
            homeHubId: profile.homeHubId,
            avatarUrl: profile.avatarURL?.absoluteString,
            showProfileToMembers: profile.showProfileToMembers
        )
    }
}

struct HubRow: Codable {
    let id: String
    let name: String
    let country: String
    let timezone: String
    let currency: String
    let membershipPriceFormatted: String
    let deregistrationDeadlineHours: Int
    let waitlistAutoPromoteCutoffHours: Int
    let defaultNoShowFeeAmount: Double
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, country, timezone, currency
        case membershipPriceFormatted = "membership_price_formatted"
        case deregistrationDeadlineHours = "deregistration_deadline_hours"
        case waitlistAutoPromoteCutoffHours = "waitlist_auto_promote_cutoff_hours"
        case defaultNoShowFeeAmount = "default_no_show_fee_amount"
        case isActive = "is_active"
    }

    func toHub() -> Hub {
        Hub(
            id: id,
            name: name,
            country: country,
            timezone: timezone,
            currency: currency,
            membershipPriceFormatted: membershipPriceFormatted,
            deregistrationDeadlineHours: deregistrationDeadlineHours,
            waitlistAutoPromoteCutoffHours: waitlistAutoPromoteCutoffHours,
            defaultNoShowFeeAmount: defaultNoShowFeeAmount,
            isActive: isActive
        )
    }
}

struct MembershipRow: Codable {
    let id: String
    let userId: String
    let hubId: String
    let status: String
    let startDate: Date
    let endDate: Date
    let source: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case hubId = "hub_id"
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case source
    }

    func toMembership() -> Membership {
        Membership(
            id: id,
            userId: userId,
            hubId: hubId,
            status: MembershipStatus(rawValue: status) ?? .none,
            startDate: startDate,
            endDate: endDate,
            source: MembershipSource(rawValue: source) ?? .stripe
        )
    }
}

struct MembershipInsert: Encodable {
    let userId: String
    let hubId: String
    let status: String
    let startDate: Date
    let endDate: Date
    let source: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hubId = "hub_id"
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case source
    }
}

struct EventRow: Codable {
    let id: String
    let hubId: String
    let category: String
    let title: String
    let description: String
    let heroImageUrl: String?
    let locationName: String
    let address: String
    let latitude: Double
    let longitude: Double
    let startsAt: Date
    let endsAt: Date
    let capacity: Int
    let registeredCount: Int
    let waitlistCount: Int
    let status: String
    let registrationOpensAt: Date?
    let registrationClosesAt: Date?
    let priceAmount: Double?
    let currency: String
    let isNonDeregisterable: Bool
    let deregistrationDeadlineHoursOverride: Int?
    let noShowFeeAmountOverride: Double?
    let hostName: String
    let attendeeAvatarUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case hubId = "hub_id"
        case category, title, description
        case heroImageUrl = "hero_image_url"
        case locationName = "location_name"
        case address, latitude, longitude
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case capacity
        case registeredCount = "registered_count"
        case waitlistCount = "waitlist_count"
        case status
        case registrationOpensAt = "registration_opens_at"
        case registrationClosesAt = "registration_closes_at"
        case priceAmount = "price_amount"
        case currency
        case isNonDeregisterable = "is_non_deregisterable"
        case deregistrationDeadlineHoursOverride = "deregistration_deadline_hours_override"
        case noShowFeeAmountOverride = "no_show_fee_amount_override"
        case hostName = "host_name"
        case attendeeAvatarUrls = "attendee_avatar_urls"
    }

    func toEvent() -> Event {
        Event(
            id: id,
            hubId: hubId,
            category: EventCategory(rawValue: category) ?? .connect,
            title: title,
            description: description,
            heroImageURL: heroImageUrl.flatMap { URL(string: $0) },
            locationName: locationName,
            address: address,
            latitude: latitude,
            longitude: longitude,
            startsAt: startsAt,
            endsAt: endsAt,
            capacity: capacity,
            registeredCount: registeredCount,
            waitlistCount: waitlistCount,
            status: EventStatus(rawValue: status) ?? .draft,
            registrationOpensAt: registrationOpensAt,
            registrationClosesAt: registrationClosesAt,
            priceAmount: priceAmount,
            currency: currency,
            isNonDeregisterable: isNonDeregisterable,
            deregistrationDeadlineHoursOverride: deregistrationDeadlineHoursOverride,
            noShowFeeAmountOverride: noShowFeeAmountOverride,
            hostName: hostName,
            attendeeAvatarURLs: (attendeeAvatarUrls ?? []).compactMap { URL(string: $0) }
        )
    }
}

struct EventRegistrationRow: Codable {
    let id: String
    let eventId: String
    let userId: String
    let status: String
    let registeredAt: Date
    let canceledAt: Date?
    let position: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case status
        case registeredAt = "registered_at"
        case canceledAt = "canceled_at"
        case position
    }

    func toEventRegistration() -> EventRegistration {
        EventRegistration(
            id: id,
            eventId: eventId,
            userId: userId,
            status: RegistrationStatus(rawValue: status) ?? .registered,
            registeredAt: registeredAt,
            canceledAt: canceledAt,
            position: position
        )
    }
}

struct EventRegistrationInsert: Encodable {
    let eventId: String
    let userId: String
    let status: String
    let position: Int?

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case userId = "user_id"
        case status
        case position
    }
}

struct NotificationDBRow: Codable {
    let id: String
    let hubId: String?
    let title: String
    let body: String
    let type: String
    let sentAt: Date
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case hubId = "hub_id"
        case title, body, type
        case sentAt = "sent_at"
        case isRead = "is_read"
    }

    func toNotification() -> AppNotification {
        AppNotification(
            id: id,
            hubId: hubId,
            title: title,
            body: body,
            type: NotificationType(rawValue: type) ?? .system,
            sentAt: sentAt,
            isRead: isRead
        )
    }
}

struct SurveyQuestionRow: Codable {
    let id: String
    let surveyId: String
    let type: String
    let prompt: String
    let options: [String]?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case surveyId = "survey_id"
        case type, prompt, options
        case orderIndex = "order_index"
    }

    func toSurveyQuestion() -> SurveyQuestion {
        SurveyQuestion(
            id: id,
            type: QuestionType(rawValue: type) ?? .text,
            prompt: prompt,
            options: options,
            orderIndex: orderIndex
        )
    }
}

struct SurveyRow: Codable {
    let id: String
    let hubId: String
    let eventId: String?
    let title: String
    let description: String
    let status: String
    let closesAt: Date?
    let surveyQuestions: [SurveyQuestionRow]?

    enum CodingKeys: String, CodingKey {
        case id
        case hubId = "hub_id"
        case eventId = "event_id"
        case title, description, status
        case closesAt = "closes_at"
        case surveyQuestions = "survey_questions"
    }

    func toSurvey() -> Survey {
        Survey(
            id: id,
            hubId: hubId,
            eventId: eventId,
            title: title,
            description: description,
            status: SurveyStatus(rawValue: status) ?? .draft,
            closesAt: closesAt,
            questions: (surveyQuestions ?? [])
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { $0.toSurveyQuestion() },
            isCompleted: false
        )
    }
}

struct SurveyResponseRow: Codable {
    let questionId: String

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
    }
}

struct SurveyResponseInsert: Encodable {
    let questionId: String
    let userId: String
    let answer: String

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case userId = "user_id"
        case answer
    }
}
