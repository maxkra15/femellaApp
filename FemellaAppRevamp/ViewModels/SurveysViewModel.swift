import SwiftUI

@Observable
@MainActor
class SurveysViewModel {
    var surveys: [Survey] = []
    var isLoading: Bool = false

    private let service = SupabaseService.shared

    var openSurveys: [Survey] {
        surveys.filter { $0.status == .open && !$0.isCompleted }
    }

    var completedSurveys: [Survey] {
        surveys.filter { $0.isCompleted || $0.status == .closed }
    }

    func loadSurveys(hubId: String) async {
        guard let userId = service.currentUserId else { return }
        isLoading = true
        do {
            var loadedSurveys = try await service.fetchSurveys(hubId: hubId)
            // Check which surveys the user has already completed
            let answeredQuestionIds = try await service.fetchCompletedSurveyIds(userId: userId)
            for i in loadedSurveys.indices {
                let surveyQuestionIds = Set(loadedSurveys[i].questions.map(\.id))
                if !surveyQuestionIds.isEmpty && surveyQuestionIds.isSubset(of: answeredQuestionIds) {
                    loadedSurveys[i].isCompleted = true
                }
            }
            surveys = loadedSurveys
        } catch {
            print("Failed to load surveys: \(error)")
        }
        isLoading = false
    }

    func submitSurvey(surveyId: String, answers: [String: String]) async {
        guard let userId = service.currentUserId else { return }
        do {
            try await service.submitSurveyResponses(userId: userId, surveyId: surveyId, answers: answers)
            if let idx = surveys.firstIndex(where: { $0.id == surveyId }) {
                surveys[idx].isCompleted = true
            }
        } catch {
            print("Submit survey error: \(error)")
        }
    }
}
