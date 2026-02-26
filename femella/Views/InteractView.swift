import SwiftUI

private enum InteractTab: Int, CaseIterable {
    case explore
    case surveys

    var title: String {
        switch self {
        case .explore: "Explore Femellas"
        case .surveys: "Surveys"
        }
    }

    var icon: String {
        switch self {
        case .explore: "sparkles"
        case .surveys: "list.clipboard"
        }
    }
}

struct InteractView: View {
    @Bindable var surveysVM: SurveysViewModel

    @State private var selectedTab = InteractTab.explore.rawValue
    @Namespace private var animation

    private var activeTab: InteractTab {
        InteractTab(rawValue: selectedTab) ?? .explore
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                segmentedPicker

                TabView(selection: $selectedTab) {
                    ExploreFemellasView()
                        .tag(InteractTab.explore.rawValue)

                    SurveysView(surveysVM: surveysVM)
                        .tag(InteractTab.surveys.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Interact")
            .navigationBarTitleDisplayMode(.inline)
            .femAmbientBackground()
        }
    }

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(InteractTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.35, extraBounce: 0.08)) {
                        selectedTab = tab.rawValue
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(FemFont.caption(weight: .semibold))
                        Text(tab.title)
                            .font(FemFont.ui(15, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(activeTab == tab ? FemColor.ivory : FemColor.darkBlue.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if activeTab == tab {
                            Capsule()
                                .fill(FemColor.darkBlue)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(FemColor.pink.opacity(0.45), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "TabBackground", in: animation)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.64))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, FemSpacing.sm)
        .padding(.bottom, FemSpacing.sm)
    }
}
