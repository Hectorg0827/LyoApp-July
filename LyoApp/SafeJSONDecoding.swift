import Foundation

// MARK: - Safe JSON Decoding Utilities
/// Utilities for handling JSON decoding errors gracefully
struct SafeJSONDecoder {
    
    static func decode<T: Codable>(_ type: T.Type, from data: Data) -> Result<T, DecodingError> {
        let decoder = JSONDecoder()
        
        // Configure decoder for common API patterns
        decoder.keyDecodingStrategy = .convertFromSnakeCase // Handles author_name -> authorCreator
        decoder.dateDecodingStrategy = .iso8601 // Standard ISO8601 date format
        
        do {
            let result = try decoder.decode(type, from: data)
            return .success(result)
        } catch let error as DecodingError {
            // Log detailed decoding error information
            logDecodingError(error, for: type, data: data)
            return .failure(error)
        } catch {
            // Convert other errors to DecodingError
            let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: error.localizedDescription))
            return .failure(decodingError)
        }
    }
    
    private static func logDecodingError<T>(_ error: DecodingError, for type: T.Type, data: Data) {
        print("🔴 JSON DECODING ERROR for \(type):")
        
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch: Expected \(type), at path: \(context.codingPath)")
            print("Debug description: \(context.debugDescription)")
            
        case .valueNotFound(let type, let context):
            print("Value not found: \(type), at path: \(context.codingPath)")
            print("Debug description: \(context.debugDescription)")
            
        case .keyNotFound(let key, let context):
            print("Key not found: \(key), at path: \(context.codingPath)")
            print("Debug description: \(context.debugDescription)")
            
        case .dataCorrupted(let context):
            print("Data corrupted at path: \(context.codingPath)")
            print("Debug description: \(context.debugDescription)")
            
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
        
        // Print raw JSON for debugging (only first 500 characters to avoid spam)
        if let jsonString = String(data: data, encoding: .utf8) {
            let truncated = String(jsonString.prefix(500))
            print("RAW JSON (truncated): \(truncated)")
            if jsonString.count > 500 {
                print("... (truncated \(jsonString.count - 500) more characters)")
            }
        } else {
            print("RAW DATA: Invalid UTF-8 encoding")
        }
    }
}

// MARK: - Enhanced Learning API with Safe Decoding
// NOTE: This extension is disabled until LearningAPIService is implemented
/*
extension LearningAPIService {
    
    /// Safely fetch resources with proper error handling
    static func safelyFetchResources(for topic: String) async -> Result<[LearningResource], Error> {
        do {
            // Construct URL safely
            guard let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://api.lyo.app/learning-resources?topic=\(encodedTopic)") else {
                return .failure(APIError.invalidURL)
            }
            
            // Perform network request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(APIError.invalidResponse)
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                return .failure(APIError.serverError(httpResponse.statusCode, nil))
            }
            
            // Decode JSON safely
            let result = SafeJSONDecoder.decode([LearningResource].self, from: data)
            
            switch result {
            case .success(let resources):
                print("✅ Successfully decoded \(resources.count) resources for topic: \(topic)")
                return .success(resources)
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            print("❌ Network error while fetching resources: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
*/
