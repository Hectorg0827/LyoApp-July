import Foundation
import SwiftUI

/**
 * Google Books API Service
 * Integrates with Google Books API to fetch educational e-books and academic content
 */
class GoogleBooksService: ObservableObject {
    private let baseURL = "https://www.googleapis.com/books/v1"
    private let apiKey = APIKeys.googleBooksAPIKey // You'll need to add this to APIKeys
    
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Search Books
    func searchBooks(
        query: String,
        subject: String = "",
        maxResults: Int = 20,
        filter: BookFilter = .ebooks
    ) async throws -> [Ebook] {
        
        var searchQuery = query
        if !subject.isEmpty {
            searchQuery += "+subject:\(subject)"
        }
        
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        var urlString = "\(baseURL)/volumes?q=\(encodedQuery)&maxResults=\(maxResults)"
        
        // Add filter for free ebooks
        switch filter {
        case .ebooks:
            urlString += "&filter=ebooks"
        case .freeEbooks:
            urlString += "&filter=free-ebooks"
        case .paidEbooks:
            urlString += "&filter=paid-ebooks"
        case .all:
            break
        }
        
        if !apiKey.isEmpty && apiKey != "YOUR_GOOGLE_BOOKS_API_KEY" {
            urlString += "&key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError("Failed to fetch Google Books data")
        }
        
        let booksResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        return booksResponse.items?.compactMap { convertToEbook($0) } ?? []
    }
    
    // MARK: - Get Book Details
    func getBookDetails(volumeId: String) async throws -> Ebook {
        var urlString = "\(baseURL)/volumes/\(volumeId)"
        
        if !apiKey.isEmpty && apiKey != "YOUR_GOOGLE_BOOKS_API_KEY" {
            urlString += "?key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let bookItem = try JSONDecoder().decode(GoogleBookItem.self, from: data)
        
        guard let ebook = convertToEbook(bookItem) else {
            throw APIError.noData("Unable to convert book data")
        }
        
        return ebook
    }
    
    // MARK: - Search by Category
    func searchByCategory(
        category: String,
        maxResults: Int = 20,
        sortBy: BookSortOrder = .relevance
    ) async throws -> [Ebook] {
        
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        var urlString = "\(baseURL)/volumes?q=subject:\(encodedCategory)&maxResults=\(maxResults)&filter=free-ebooks"
        
        switch sortBy {
        case .relevance:
            urlString += "&orderBy=relevance"
        case .newest:
            urlString += "&orderBy=newest"
        }
        
        if !apiKey.isEmpty && apiKey != "YOUR_GOOGLE_BOOKS_API_KEY" {
            urlString += "&key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        return response.items?.compactMap { convertToEbook($0) } ?? []
    }
    
    // MARK: - Get Popular Educational Books
    func getPopularEducationalBooks(subject: String = "education") async throws -> [Ebook] {
        return try await searchByCategory(category: subject, maxResults: 40, sortBy: .relevance)
    }
    
    // MARK: - Search Free Academic Books
    func searchFreeAcademicBooks(field: String, maxResults: Int = 20) async throws -> [Ebook] {
        let query = "subject:\(field)+inauthor:university OR inauthor:professor OR inauthor:academic"
        return try await searchBooks(query: query, maxResults: maxResults, filter: .freeEbooks)
    }
    
    // MARK: - Get Book Preview
    func getBookPreview(volumeId: String) async throws -> String? {
        var urlString = "\(baseURL)/volumes/\(volumeId)"
        
        if !apiKey.isEmpty && apiKey != "YOUR_GOOGLE_BOOKS_API_KEY" {
            urlString += "?key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let bookItem = try JSONDecoder().decode(GoogleBookItem.self, from: data)
        
        return bookItem.volumeInfo.previewLink
    }
    
    // MARK: - Helper Functions
    private func convertToEbook(_ item: GoogleBookItem) -> Ebook? {
        let volumeInfo = item.volumeInfo
        
        // Skip books without essential information
        guard let title = volumeInfo.title,
              let authors = volumeInfo.authors,
              !authors.isEmpty else {
            return nil
        }
        
        let description = volumeInfo.description ?? "No description available"
        let coverURL = volumeInfo.imageLinks?.thumbnail ?? volumeInfo.imageLinks?.smallThumbnail ?? ""
        let pdfURL = volumeInfo.previewLink ?? ""
        let category = volumeInfo.categories?.first ?? "General"
        let pages = volumeInfo.pageCount ?? 0
        let publishedDate = parsePublishedDate(volumeInfo.publishedDate)
        let language = volumeInfo.language ?? "en"
        let rating = volumeInfo.averageRating ?? 0.0
        
        // Determine file size (estimate based on page count)
        let estimatedFileSize = pages > 0 ? "\(Int(Double(pages) * 0.1))MB" : "Unknown"
        
        return Ebook(
            id: UUID(),
            title: title,
            author: authors.joined(separator: ", "),
            description: description,
            coverImageURL: coverURL,
            pdfURL: pdfURL,
            category: category,
            pages: pages,
            fileSize: estimatedFileSize,
            rating: rating,
            downloadCount: volumeInfo.ratingsCount ?? 0,
            isBookmarked: false,
            readProgress: 0.0,
            publishedDate: publishedDate,
            language: language,
            tags: volumeInfo.categories ?? []
        )
    }
    
    private func parsePublishedDate(_ dateString: String?) -> Date {
        guard let dateString = dateString else { return Date() }
        
        let formatters = [
            DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd" },
            DateFormatter().apply { $0.dateFormat = "yyyy-MM" },
            DateFormatter().apply { $0.dateFormat = "yyyy" }
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return Date()
    }
}

// MARK: - Google Books API Response Models
struct GoogleBooksResponse: Codable {
    let kind: String
    let totalItems: Int
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let kind: String
    let id: String
    let etag: String
    let selfLink: String
    let volumeInfo: GoogleBookVolumeInfo
    let accessInfo: GoogleBookAccessInfo?
    let saleInfo: GoogleBookSaleInfo?
}

struct GoogleBookVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [GoogleBookIdentifier]?
    let readingModes: GoogleBookReadingModes?
    let pageCount: Int?
    let printType: String?
    let categories: [String]?
    let averageRating: Double?
    let ratingsCount: Int?
    let maturityRating: String?
    let allowAnonLogging: Bool?
    let contentVersion: String?
    let panelizationSummary: GoogleBookPanelization?
    let imageLinks: GoogleBookImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
    let canonicalVolumeLink: String?
}

struct GoogleBookIdentifier: Codable {
    let type: String
    let identifier: String
}

struct GoogleBookReadingModes: Codable {
    let text: Bool
    let image: Bool
}

struct GoogleBookPanelization: Codable {
    let containsEpubBubbles: Bool
    let containsImageBubbles: Bool
}

struct GoogleBookImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?
}

struct GoogleBookAccessInfo: Codable {
    let country: String
    let viewability: String
    let embeddable: Bool
    let publicDomain: Bool
    let textToSpeechPermission: String
    let epub: GoogleBookFormatInfo
    let pdf: GoogleBookFormatInfo
    let webReaderLink: String?
    let accessViewStatus: String
    let quoteSharingAllowed: Bool
}

struct GoogleBookFormatInfo: Codable {
    let isAvailable: Bool
    let acsTokenLink: String?
}

struct GoogleBookSaleInfo: Codable {
    let country: String
    let saleability: String
    let isEbook: Bool
    let listPrice: GoogleBookPrice?
    let retailPrice: GoogleBookPrice?
    let buyLink: String?
    let offers: [GoogleBookOffer]?
}

struct GoogleBookPrice: Codable {
    let amount: Double
    let currencyCode: String
}

struct GoogleBookOffer: Codable {
    let finskyOfferType: Int
    let listPrice: GoogleBookPrice
    let retailPrice: GoogleBookPrice
}

// MARK: - Enums
enum BookFilter: String, CaseIterable {
    case ebooks = "ebooks"
    case freeEbooks = "free-ebooks"
    case paidEbooks = "paid-ebooks"
    case all = "all"
}

enum BookSortOrder: String, CaseIterable {
    case relevance = "relevance"
    case newest = "newest"
}

// MARK: - Extension for applying configuration
extension NSObjectProtocol {
    func apply(_ configuration: (Self) -> Void) -> Self {
        configuration(self)
        return self
    }
}
