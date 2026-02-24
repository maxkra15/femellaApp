import Foundation
import Observation

@Observable
final class ExploreViewModel {
    var profiles: [UserProfile] = []
    var filteredProfiles: [UserProfile] = []
    var isLoading: Bool = false
    var searchText: String = "" {
        didSet { applyFilters() }
    }
    var selectedHubId: String? {
        didSet { applyFilters() }
    }
    
    @MainActor
    func loadProfiles() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let fetched = try await SupabaseService.shared.fetchExploreProfiles()
            let currentId = SupabaseService.shared.currentUserId
            self.profiles = fetched.filter { $0.id != currentId }
            applyFilters()
        } catch {
            print("Failed to load explore profiles: \(error)")
        }
        isLoading = false
    }
    
    func applyFilters() {
        var filtered = profiles
        
        if let hubId = selectedHubId {
            filtered = filtered.filter { $0.homeHubId == hubId }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.company.localizedCaseInsensitiveContains(searchText) ||
                $0.jobTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredProfiles = filtered
    }
}
