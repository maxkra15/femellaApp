import Foundation

nonisolated enum EventCategory: String, Codable, CaseIterable, Sendable {
    case connect = "Connect"
    case learn = "Learn"
    case grow = "Grow"
}

nonisolated enum EventStatus: String, Codable, Sendable {
    case draft
    case published
    case canceled
    case completed
}

nonisolated struct Event: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let hubId: String
    let category: EventCategory
    let title: String
    let description: String
    let heroImageURL: URL?
    let locationName: String
    let address: String
    let latitude: Double
    let longitude: Double
    let startsAt: Date
    let endsAt: Date
    let capacity: Int
    let registeredCount: Int
    let waitlistCount: Int
    let status: EventStatus
    let registrationOpensAt: Date?
    let registrationClosesAt: Date?
    let priceAmount: Double?
    let currency: String
    let isNonDeregisterable: Bool
    let deregistrationDeadlineHoursOverride: Int?
    let noShowFeeAmountOverride: Double?
    let hostName: String
    let attendeeAvatarURLs: [URL]

    var isFree: Bool { priceAmount == nil || priceAmount == 0 }
    var isFull: Bool { registeredCount >= capacity }
    var isPast: Bool { endsAt < Date() }

    var priceDisplay: String {
        guard let amount = priceAmount, amount > 0 else { return "Free" }
        return "\(currency) \(String(format: "%.2f", amount))"
    }

    var spotsLeft: Int { max(0, capacity - registeredCount) }
}
