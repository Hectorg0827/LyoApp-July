import SwiftUI
import Combine

// MARK: - Learning Search View Model
/// Manages the state and logic for the learning content search.
class LearningSearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""
    @Published var searchResults: [LearningResource] = []
    @Published var isSearching: Bool = false
    @Published var recentSearches: [String] = []
    @Published var popularTopics: [String] = ["SwiftUI", "AI/ML", "Design Systems", "Concurrency"]
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let apiService = LearningAPIService.shared
    
    // MARK: - Initialization
    init() {
        setupDebounce()
        loadRecentSearches()
    }
    
    // MARK: - Public Methods
    func updateSearchText(_ newText: String) {
        self.searchText = newText
    }
    
    func performImmediateSearch(_ query: String) {
        self.searchText = query
        self.debouncedSearchText = query
        search(for: query)
    }
    
    func addToRecentSearches(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        
        if recentSearches.count > 5 {
            recentSearches.removeLast()
        }
        
        saveRecentSearches()
    }
    
    func removeFromRecentSearches(at offsets: IndexSet) {
        recentSearches.remove(atOffsets: offsets)
        saveRecentSearches()
    }
    
    // MARK: - Private Methods
    private func setupDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] query in
                self?.debouncedSearchText = query
                if !query.isEmpty {
                    self?.isSearching = true
                }
            })
            .flatMap { [weak self] query -> AnyPublisher<[LearningResource], Never> in
                guard let self = self, !query.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }
                return self.apiService.searchResources(query: query)
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.searchResults = results
                self?.isSearching = false
                if !(self?.debouncedSearchText.isEmpty ?? true) {
                    self?.addToRecentSearches(self?.debouncedSearchText ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    private func search(for query: String) {
        isSearching = true
        apiService.searchResources(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isSearching = false
                if case .failure(let error) = completion {
                    print("❌ Search failed: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] results in
                self?.searchResults = results
                self?.addToRecentSearches(query)
            })
            .store(in: &cancellables)
    }
    
    private func loadRecentSearches() {
        self.recentSearches = UserDefaults.standard.stringArray(forKey: "recentLearningSearches") ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentLearningSearches")
    }
}

class SearchSuggestionsViewModel: ObservableObject {
    @Published var suggestions: [String] = []
    
    func fetchSuggestions(for query: String) {
        // In a real app, this would call an API.
        // For now, we'll simulate with some sample data.
        let allTopics = ["SwiftUI", "Combine", "Async/Await", "Core Data", "Machine Learning", "Design Patterns", "Architecture"]
        if query.isEmpty {
            self.suggestions = []
        } else {
            self.suggestions = allTopics.filter { $0.lowercased().contains(query.lowercased()) }
        }
    }
}
