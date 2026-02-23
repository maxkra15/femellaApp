import SwiftUI

struct SurveysView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var surveysVM: SurveysViewModel
    @State private var selectedSurvey: Survey?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.xl) {
                    if surveysVM.isLoading {
                        ProgressView()
                            .tint(FemColor.pink)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        if !surveysVM.openSurveys.isEmpty {
                            VStack(alignment: .leading, spacing: FemSpacing.md) {
                                Text("Open Surveys")
                                    .font(FemFont.title(20))
                                    .foregroundStyle(FemColor.darkBlue)

                                ForEach(surveysVM.openSurveys) { survey in
                                    SurveyCard(survey: survey, isOpen: true) {
                                        selectedSurvey = survey
                                    }
                                }
                            }
                        }

                        if !surveysVM.completedSurveys.isEmpty {
                            VStack(alignment: .leading, spacing: FemSpacing.md) {
                                Text("Completed")
                                    .font(FemFont.title(20))
                                    .foregroundStyle(FemColor.darkBlue)

                                ForEach(surveysVM.completedSurveys) { survey in
                                    SurveyCard(survey: survey, isOpen: false) {}
                                }
                            }
                        }

                        if surveysVM.openSurveys.isEmpty && surveysVM.completedSurveys.isEmpty {
                            ContentUnavailableView("No Surveys", systemImage: "doc.text", description: Text("Surveys will appear here when available."))
                                .frame(minHeight: 300)
                        }
                    }
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .background(FemColor.ivory.ignoresSafeArea())
            .navigationTitle("Surveys")
            .task { await surveysVM.loadSurveys(hubId: appVM.selectedHubId) }
            .sheet(item: $selectedSurvey) { survey in
                SurveyDetailView(survey: survey, surveysVM: surveysVM)
            }
        }
    }
}

private struct SurveyCard: View {
    let survey: Survey
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.title)
                        .font(.headline)
                        .foregroundStyle(FemColor.darkBlue)
                    Text(survey.description)
                        .font(.caption)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()

                if isOpen {
                    Button(action: action) {
                        Text("Take")
                            .femSecondaryButton()
                    }
                } else {
                    StatusBadge(text: "Done", color: FemColor.green)
                }
            }

            if let closes = survey.closesAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(isOpen ? "Closes \(closes.formatted(.dateTime.month(.abbreviated).day()))" : "Closed \(closes.formatted(.dateTime.month(.abbreviated).day()))")
                }
                .font(.caption2)
                .foregroundStyle(FemColor.darkBlue.opacity(0.3))
            }
        }
        .padding(FemSpacing.lg)
        .femCard()
    }
}

struct SurveyDetailView: View {
    let survey: Survey
    let surveysVM: SurveysViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var answers: [String: String] = [:]
    @State private var isSubmitting: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FemSpacing.xl) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(survey.title)
                            .font(FemFont.display(22))
                            .foregroundStyle(FemColor.darkBlue)
                        Text(survey.description)
                            .font(.subheadline)
                            .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                    }

                    ForEach(survey.questions.sorted(by: { $0.orderIndex < $1.orderIndex })) { question in
                        QuestionView(question: question, answer: Binding(
                            get: { answers[question.id] ?? "" },
                            set: { answers[question.id] = $0 }
                        ))
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit")
                            }
                        }
                        .femPrimaryButton(isEnabled: !answers.isEmpty)
                    }
                    .disabled(answers.isEmpty || isSubmitting)
                }
                .padding(FemSpacing.lg)
            }
            .background(FemColor.ivory.ignoresSafeArea())
            .navigationTitle("Survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        await surveysVM.submitSurvey(surveyId: survey.id, answers: answers)
        isSubmitting = false
        dismiss()
    }
}

private struct QuestionView: View {
    let question: SurveyQuestion
    @Binding var answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            Text(question.prompt)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FemColor.darkBlue)

            switch question.type {
            case .likert:
                HStack(spacing: 8) {
                    ForEach(question.options ?? [], id: \.self) { option in
                        Button {
                            answer = option
                        } label: {
                            Text(option)
                                .font(.subheadline.weight(.medium))
                                .frame(width: 44, height: 44)
                                .background(answer == option ? FemColor.pink : FemColor.ivory)
                                .foregroundStyle(answer == option ? .white : FemColor.darkBlue)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().strokeBorder(answer == option ? Color.clear : FemColor.darkBlue.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }

            case .multipleChoice:
                VStack(spacing: 6) {
                    ForEach(question.options ?? [], id: \.self) { option in
                        Button {
                            answer = option
                        } label: {
                            HStack {
                                Circle()
                                    .strokeBorder(answer == option ? FemColor.pink : FemColor.darkBlue.opacity(0.15), lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        if answer == option {
                                            Circle()
                                                .fill(FemColor.pink)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                Text(option)
                                    .foregroundStyle(FemColor.darkBlue)
                                Spacer()
                            }
                            .font(.subheadline)
                            .padding(12)
                            .background(answer == option ? FemColor.pink.opacity(0.06) : FemColor.ivory)
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(answer == option ? FemColor.pink.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }

            case .text:
                TextField("Your answer...", text: $answer, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(FemColor.ivory)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(FemColor.darkBlue.opacity(0.06), lineWidth: 1)
                    )
            }
        }
        .padding(FemSpacing.lg)
        .background(FemColor.cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: FemColor.darkBlue.opacity(0.04), radius: 8, y: 4)
    }
}
