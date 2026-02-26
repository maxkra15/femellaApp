import SwiftUI

private struct HubCluster: Identifiable {
    let id: String
    let title: String
    let profiles: [UserProfile]
}

struct ExploreFemellasView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var vm = ExploreViewModel()
    @Namespace private var memberTransition

    private var activeHubs: [Hub] {
        appVM.hubs.filter(\.isActive).sorted { $0.name < $1.name }
    }

    private var hubNameById: [String: String] {
        Dictionary(uniqueKeysWithValues: activeHubs.map { ($0.id, $0.name) })
    }

    private var visibleClusters: [HubCluster] {
        let grouped = Dictionary(grouping: vm.filteredProfiles, by: \.homeHubId)

        if let selectedHubId = vm.selectedHubId {
            guard let profiles = grouped[selectedHubId], !profiles.isEmpty else { return [] }
            return [
                HubCluster(
                    id: selectedHubId,
                    title: hubNameById[selectedHubId] ?? "Hub",
                    profiles: sortedProfiles(profiles)
                )
            ]
        }

        var clusters = activeHubs.compactMap { hub -> HubCluster? in
            guard let profiles = grouped[hub.id], !profiles.isEmpty else { return nil }
            return HubCluster(id: hub.id, title: hub.name, profiles: sortedProfiles(profiles))
        }

        for (hubId, profiles) in grouped where hubNameById[hubId] == nil && !profiles.isEmpty {
            clusters.append(HubCluster(id: hubId, title: "Hub", profiles: sortedProfiles(profiles)))
        }

        return clusters
    }

    var body: some View {
        VStack(spacing: 0) {
            hubChips
            searchBar

            ScrollView {
                if vm.isLoading {
                    loadingSkeleton
                } else if visibleClusters.isEmpty {
                    ContentUnavailableView("No Femellas Found", systemImage: "person.2.slash")
                        .frame(minHeight: 220)
                } else {
                    VStack(alignment: .leading, spacing: FemSpacing.lg) {
                        ForEach(visibleClusters) { cluster in
                            HubBubbleCluster(
                                cluster: cluster,
                                transitionNamespace: memberTransition
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, FemSpacing.sm)
                }
            }
        }
        .femAmbientBackground()
        .task {
            await vm.loadProfiles()
        }
    }

    private func sortedProfiles(_ profiles: [UserProfile]) -> [UserProfile] {
        profiles.sorted { left, right in
            left.firstName.localizedCaseInsensitiveCompare(right.firstName) == .orderedAscending
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FemColor.darkBlue.opacity(0.55))
            TextField("Search", text: $vm.searchText)
                .font(FemFont.body(15))
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(Color.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(FemColor.darkBlue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: FemColor.darkBlue.opacity(0.08), radius: 10, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var hubChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                HubChip(title: "All", isSelected: vm.selectedHubId == nil) {
                    vm.selectedHubId = nil
                }

                ForEach(activeHubs) { hub in
                    HubChip(title: hub.name, isSelected: vm.selectedHubId == hub.id) {
                        vm.selectedHubId = hub.id
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: FemSpacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: FemSpacing.sm) {
                    SkeletonBlock(width: 120, height: 12, cornerRadius: 6)
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: 8) {
                                SkeletonCircle(size: 74)
                                SkeletonBlock(width: 64, height: 10, cornerRadius: 5)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, FemSpacing.md)
    }
}

private struct HubBubbleCluster: View {
    let cluster: HubCluster
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: FemSpacing.sm) {
            Text(cluster.title)
                .font(FemFont.caption(weight: .semibold))
                .foregroundStyle(FemColor.darkBlue.opacity(0.6))

            BubbleFlowLayout(spacing: 8, rowSpacing: 12) {
                ForEach(Array(cluster.profiles.enumerated()), id: \.element.id) { index, profile in
                    NavigationLink {
                        ExploreMemberDetailView(
                            profile: profile,
                            transitionNamespace: transitionNamespace
                        )
                    } label: {
                        MemberOrb(
                            profile: profile,
                            seed: index,
                            transitionNamespace: transitionNamespace
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MemberOrb: View {
    let profile: UserProfile
    let seed: Int
    let transitionNamespace: Namespace.ID

    @State private var isFloating = false

    private var duration: Double { 2.6 + Double(seed % 5) * 0.22 }
    private var amplitude: CGFloat { 3 + CGFloat(seed % 4) }

    var body: some View {
        VStack(spacing: 6) {
            AvatarView(initials: profile.initials, url: profile.avatarURL, size: 74)
                .overlay(
                    Circle()
                        .strokeBorder(FemColor.darkBlue.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: FemColor.darkBlue.opacity(0.12), radius: 8, y: 4)
                .matchedTransitionSource(id: profile.id, in: transitionNamespace)

            Text(profile.firstName)
                .font(FemFont.caption(12, weight: .semibold))
                .foregroundStyle(FemColor.darkBlue)
                .lineLimit(1)
        }
        .frame(width: 90)
        .offset(y: isFloating ? -amplitude : amplitude)
        .onAppear {
            guard !isFloating else { return }
            withAnimation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed % 6) * 0.08)
            ) {
                isFloating = true
            }
        }
    }
}

private struct HubChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FemFont.ui(14, weight: .semibold))
                .foregroundStyle(isSelected ? FemColor.ivory : FemColor.darkBlue.opacity(0.75))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? FemColor.darkBlue : Color.white.opacity(0.64))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? FemColor.pink.opacity(0.45) : FemColor.darkBlue.opacity(0.08),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct BubbleFlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
