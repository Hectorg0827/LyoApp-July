import Foundation
import SwiftUI

class StorageManager {
    static let shared = StorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - User Preferences
    func saveUserPreference<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func loadUserPreference<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - File Caching
    func cacheData<T: Codable>(_ data: T, filename: String) async {
        let url = documentsDirectory.appendingPathComponent("\(filename).json")
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
        } catch {
            print("Failed to cache data: \(error)")
        }
    }
    
    func loadCachedData<T: Codable>(_ type: T.Type, filename: String) async -> T? {
        let url = documentsDirectory.appendingPathComponent("\(filename).json")
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load cached data: \(error)")
            return nil
        }
    }
    
    func deleteCachedFile(filename: String) {
        let url = documentsDirectory.appendingPathComponent("\(filename).json")
        try? FileManager.default.removeItem(at: url)
    }
    
    func clearAllCache() {
        let contents = try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        contents?.forEach { url in
            if url.pathExtension == "json" {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
