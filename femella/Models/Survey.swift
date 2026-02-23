import Foundation

nonisolated enum SurveyStatus: String, Codable, Sendable {
    case draft
    case open
    case closed
}

nonisolated enum QuestionType: String, Codable, Sendable {
    case likert
    case multipleChoice = "mcq"
    case text
}

nonisolated struct Survey: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let hubId: String
    let eventId: String?
    let title: String
    let description: String
    let status: SurveyStatus
    let closesAt: Date?
    let questions: [SurveyQuestion]
    var isCompleted: Bool
}

nonisolated struct SurveyQuestion: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let type: QuestionType
    let prompt: String
    let options: [String]?
    let orderIndex: Int
}
