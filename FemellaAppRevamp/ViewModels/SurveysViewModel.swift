import SwiftUI

@Observable
@MainActor
class SurveysViewModel {
    var surveys: [Survey] = []
    var isLoading: Bool = false

    var openSurveys: [Survey] {
        surveys.filter { $0.status == .open && !$0.isCompleted }
    }

    var completedSurveys: [Survey] {
        surveys.filter { $0.isCompleted || $0.status == .closed }
    }

    func loadSurveys() async {
        isLoading = true
        try? await Task.sleep(for: .seconds(0.3))
        surveys = MockDataService.sampleSurveys()
        isLoading = false
    }

    func submitSurvey(surveyId: String, answers: [String: String]) async {
        try? await Task.sleep(for: .seconds(0.5))
        if let idx = surveys.firstIndex(where: { $0.id == surveyId }) {
            surveys[idx].isCompleted = true
        }
    }
}
