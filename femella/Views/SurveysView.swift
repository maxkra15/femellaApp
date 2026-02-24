import SwiftUI

struct SurveysView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var surveysVM: SurveysViewModel
    @State private var selectedSurvey: Survey?

    var body: some View {
        ScrollView {
            VStack(spacing: FemSpacing.xl) {
                surveyHeaderCard

                if surveysVM.isLoading {
                    ProgressView()
                        .tint(FemColor.darkBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    if !surveysVM.openSurveys.isEmpty {
                        VStack(alignment: .leading, spacing: FemSpacing.md) {
                            Text("Ready for You")
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
                        ContentUnavailableView(
                            "No Surveys Yet",
                            systemImage: "text.clipboard",
                            description: Text("New surveys will appear here as soon as they are published.")
                        )
                        .frame(minHeight: 300)
                    }
                }
            }
            .padding(.horizontal, FemSpacing.lg)
            .padding(.bottom, FemSpacing.xxl)
        }
        .background(FemColor.ivory.ignoresSafeArea())
        .task { await surveysVM.loadSurveys(hubId: appVM.selectedHubId) }
        .sheet(item: $selectedSurvey) { survey in
            SurveyDetailView(survey: survey, surveysVM: surveysVM)
        }
    }

    private var surveyHeaderCard: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            Text("Community Pulse")
                .font(FemFont.title(24))
                .foregroundStyle(FemColor.ivory)

            Text("Short surveys keep femella programming sharp and relevant.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FemColor.ivory.opacity(0.88))

            HStack(spacing: FemSpacing.sm) {
                SurveyMetricPill(
                    title: "Open",
                    count: surveysVM.openSurveys.count,
                    icon: "sparkles"
                )
                SurveyMetricPill(
                    title: "Completed",
                    count: surveysVM.completedSurveys.count,
                    icon: "checkmark.circle.fill"
                )
            }
        }
        .padding(FemSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FemColor.heroGradient)
        .clipShape(.rect(cornerRadius: 24))
        .overlay(alignment: .topTrailing) {
            CirclePattern(size: 104, opacity: 0.2)
                .blendMode(.screen)
                .offset(x: 26, y: -24)
                .allowsHitTesting(false)
        }
    }
}

private struct SurveyMetricPill: View {
    let title: String
    let count: Int
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text("\(count)")
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(FemColor.darkBlue)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
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
                        Label("Take now", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FemColor.ivory)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FemColor.darkBlue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
        .background(
            LinearGradient(
                colors: [Color.white, FemColor.darkBlue.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isOpen ? FemColor.darkBlue.opacity(0.12) : FemColor.green.opacity(0.25),
                    lineWidth: 1
                )
        )
        .shadow(color: FemColor.darkBlue.opacity(0.05), radius: 9, y: 4)
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
                LikertScaleView(answer: $answer)

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

// MARK: - Likert Scale (1–5)

private struct LikertScaleView: View {
    @Binding var answer: String

    private let steps = ["1", "2", "3", "4", "5"]
    private let labels = ["Strongly\nDisagree", "Disagree", "Neutral", "Agree", "Strongly\nAgree"]

    // Colour shifts from warm-neutral to brand pink as value increases
    private func bubbleColor(for step: String) -> Color {
        guard let v = Int(step) else { return FemColor.pink }
        let t = Double(v - 1) / 4.0   // 0…1
        return Color(
            hue: 0.93 - (t * 0.05),   // slight hue shift pink→pink-dark
            saturation: 0.7 + (t * 0.28),
            brightness: 0.96 - (t * 0.06)
        )
    }

    var body: some View {
        VStack(spacing: FemSpacing.sm) {
            // Track + bubbles
            ZStack(alignment: .center) {
                // Connecting track line
                RoundedRectangle(cornerRadius: 2)
                    .fill(FemColor.darkBlue.opacity(0.08))
                    .frame(height: 4)
                    .padding(.horizontal, 26)

                // Filled progress track
                if let selected = Int(answer), selected >= 1 {
                    GeometryReader { geo in
                        let totalWidth = geo.size.width - 52   // same inset as track padding
                        let step = totalWidth / 4.0
                        let progress = CGFloat(selected - 1) * step

                        RoundedRectangle(cornerRadius: 2)
                            .fill(FemColor.pinkGradient)
                            .frame(width: progress, height: 4)
                            .padding(.leading, 26)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: answer)
                    }
                    .frame(height: 4)
                }

                // Bubbles
                HStack(spacing: 0) {
                    ForEach(steps, id: \.self) { step in
                        let isSelected = answer == step

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                answer = step
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? bubbleColor(for: step) : FemColor.ivory)
                                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                                    .shadow(
                                        color: isSelected ? FemColor.pink.opacity(0.4) : .clear,
                                        radius: 8, y: 4
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isSelected ? Color.clear : FemColor.darkBlue.opacity(0.12),
                                                lineWidth: 1.5
                                            )
                                    )

                                Text(step)
                                    .font(isSelected ? .system(size: 17, weight: .bold) : .system(size: 15, weight: .medium))
                                    .foregroundStyle(isSelected ? .white : FemColor.darkBlue.opacity(0.5))
                                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(isSelected ? 1.0 : 0.95)
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
                    }
                }
            }
            .frame(height: 54)

            // Endpoint labels
            HStack {
                Text("Strongly\nDisagree")
                    .multilineTextAlignment(.center)
                Spacer()
                Text("Strongly\nAgree")
                    .multilineTextAlignment(.center)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(FemColor.darkBlue.opacity(0.35))
            .padding(.horizontal, 4)

            // Selected label chip
            if !answer.isEmpty, let idx = steps.firstIndex(of: answer) {
                Text(labels[idx])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FemColor.pink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(FemColor.pink.opacity(0.1))
                    .clipShape(Capsule())
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.vertical, FemSpacing.sm)
    }
}
