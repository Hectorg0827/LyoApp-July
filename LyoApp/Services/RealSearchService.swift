//
//  RealSearchService.swift
//  LyoApp
//
//  PRODUCTION-ONLY SEARCH SERVICE
//  This service searches REAL data from the backend API.
//  🚫 NO MOCK DATA - PRODUCTION ONLY
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RealSearchService: ObservableObject {
    static let shared = RealSearchService()
    
    // MARK: - Published Properties
    @Published var searchResults: [SearchResultItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchQuery: String = ""
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private var searchTask: Task<Void, Never>?
    
    private init() {
        print("✅ RealSearchService initialized - PRODUCTION MODE ONLY")
        print("🚫 Mock search data: DISABLED")
    }
    
    // MARK: - Search
    func search(query: String, type: SearchType = .all) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchQuery = query
        isLoading = true
        error = nil
        
        print("🔍 Searching backend for: '\(query)' (type: \(type))")
        
        searchTask = Task {
            do {
                var results: [SearchResultItem] = []
                
                switch type {
                case .all:
                    // Search both users and content
                    async let userResults = apiClient.searchUsers(query, limit: 10)
                    async let contentResults = apiClient.searchContent(query, limit: 10)
                    
                    let (users, content) = try await (userResults, contentResults)
                    
                    // Convert to SearchResultItem
                    results.append(contentsOf: users.users.map { SearchResultItem.user($0) })
                    results.append(contentsOf: content.posts.map { SearchResultItem.post($0) })
                    
                case .users:
                    let response = try await apiClient.searchUsers(query, limit: 20)
                    results = response.users.map { SearchResultItem.user($0) }
                    
                case .posts:
                    let response = try await apiClient.searchContent(query, limit: 20)
                    results = response.posts.map { SearchResultItem.post($0) }
                    
                case .courses:
                    // TODO: Add course search endpoint to backend
                    print("⚠️ Course search not yet implemented in backend")
                    results = []
                }
                
                if !Task.isCancelled {
                    self.searchResults = results
                    self.isLoading = false
                    print("✅ Search complete: \(results.count) results")
                }
                
            } catch {
                if !Task.isCancelled {
                    print("❌ Search failed: \(error)")
                    self.error = error
                    self.isLoading = false
                    self.searchResults = []
                }
            }
        }
        
        await searchTask?.value
    }
    
    // MARK: - Clear Results
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        searchQuery = ""
        error = nil
    }
}

// MARK: - Search Type
enum SearchType {
    case all
    case users
    case posts
    case courses
}

// MARK: - Search Result Item
enum SearchResultItem: Identifiable {
    case user(User)
    case post(FeedItem)
    case course(Course)
    
    var id: String {
        switch self {
        case .user(let user):
            return "user-\(user.id)"
        case .post(let post):
            return "post-\(post.id)"
        case .course(let course):
            return "course-\(course.id)"
        }
    }
}

// MARK: - Course Result (Placeholder)
// This is now replaced by the canonical Course model.
// struct CourseResult: Identifiable, Codable { ... }
