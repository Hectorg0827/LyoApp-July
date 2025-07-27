import SwiftUI
import Combine

// MARK: - Learning Search View Model
/// Manages the state and logic for the learning content search.
@MainActor
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
                
                return Future<[LearningResource], Never> { promise in
                    Task { @MainActor in
                        do {
                            let searchRequest = LearningSearchRequest(query: query)
                            let response = try await self.apiService.searchResources(searchRequest)
                            promise(.success(response.resources))
                        } catch {
                            print("❌ Search failed: \(error.localizedDescription)")
                            promise(.success([]))
                        }
                    }
                }
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
        
        Task { @MainActor in
            do {
                let searchRequest = LearningSearchRequest(query: query)
                let response = try await apiService.searchResources(searchRequest)
                self.searchResults = response.resources
                self.addToRecentSearches(query)
            } catch {
                print("❌ Search failed: \(error.localizedDescription)")
                self.searchResults = []
            }
            self.isSearching = false
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "learning_recent_searches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "learning_recent_searches")
        }
    }
}

// MARK: - Search Suggestions View Model
@MainActor
class SearchSuggestionsViewModel: ObservableObject {
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    
    private let apiService = LearningAPIService.shared
    
    func loadSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        isLoading = true
        
        // Simulate loading suggestions - in real app, this would call an API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.suggestions = [
                "\(query) basics",
                "\(query) tutorial",
                "\(query) advanced",
                "\(query) examples",
                "\(query) best practices"
            ]
            self.isLoading = false
        }
    }
}
