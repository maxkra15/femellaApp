import SwiftUI

struct SurveysView: View {
    @Bindable var surveysVM: SurveysViewModel
    @State private var selectedSurvey: Survey?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.xl) {
                    if surveysVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        if !surveysVM.openSurveys.isEmpty {
                            VStack(alignment: .leading, spacing: FemSpacing.md) {
                                Text("Open Surveys")
                                    .font(.title3.bold())
                                    .foregroundStyle(FemColor.navy)

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
                                    .font(.title3.bold())
                                    .foregroundStyle(FemColor.navy)

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
            .background(FemColor.blush.ignoresSafeArea())
            .navigationTitle("Surveys")
            .task { await surveysVM.loadSurveys() }
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
                        .foregroundStyle(FemColor.navy)
                    Text(survey.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isOpen {
                    Button(action: action) {
                        Text("Take")
                            .femSecondaryButton()
                    }
                } else {
                    StatusBadge(text: "Done", color: FemColor.success)
                }
            }

            if let closes = survey.closesAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(isOpen ? "Closes \(closes.formatted(.dateTime.month(.abbreviated).day()))" : "Closed \(closes.formatted(.dateTime.month(.abbreviated).day()))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
                            .font(.title3.bold())
                            .foregroundStyle(FemColor.navy)
                        Text(survey.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
            .background(FemColor.blush.ignoresSafeArea())
            .navigationTitle("Survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                .foregroundStyle(FemColor.navy)

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
                                .background(answer == option ? FemColor.accentPink : Color(.secondarySystemBackground))
                                .foregroundStyle(answer == option ? .white : .primary)
                                .clipShape(Circle())
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
                                Image(systemName: answer == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(answer == option ? FemColor.accentPink : .secondary)
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .font(.subheadline)
                            .padding(12)
                            .background(answer == option ? FemColor.accentPink.opacity(0.06) : Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 10))
                        }
                    }
                }

            case .text:
                TextField("Your answer...", text: $answer, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(FemSpacing.lg)
        .background(FemColor.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
    }
}
