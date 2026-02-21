import Foundation

nonisolated struct Hub: Identifiable, Hashable, Codable, Sendable {
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
}
