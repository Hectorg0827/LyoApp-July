//
//  Avatar3DPersistence.swift
//  LyoApp
//
//  3D Avatar persistence and migration system
//  Connects Avatar3DModel with existing AvatarStore
//  Created: October 10, 2025
//

import SwiftUI
import Foundation

// MARK: - Avatar 3D Storage Manager

@MainActor
class Avatar3DStorageManager: ObservableObject {
    
    // MARK: - Storage Keys
    
    private let avatar3DKey = "avatar3D_model"
    private let migrationKey = "avatar3D_migrated_from_2D"
    
    private let avatar3DURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar3D.json")
    }()
    
    // MARK: - Save Methods
    
    /// Save Avatar3DModel to persistent storage
    func save(avatar: Avatar3DModel) throws {
        // Save to JSON file
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(avatar)
        try data.write(to: avatar3DURL, options: .atomic)
        
        // Also save to UserDefaults for quick access
        UserDefaults.standard.set(data, forKey: avatar3DKey)
        
        print("✅ [Avatar3DPersistence] Saved 3D avatar: \(avatar.name)")
    }
    
    /// Load Avatar3DModel from persistent storage
    func load() -> Avatar3DModel? {
        // Try loading from file first
        if let data = try? Data(contentsOf: avatar3DURL),
           let avatar = try? JSONDecoder().decode(Avatar3DModel.self, from: data) {
            print("✅ [Avatar3DPersistence] Loaded 3D avatar from file: \(avatar.name)")
            return avatar
        }
        
        // Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: avatar3DKey),
           let avatar = try? JSONDecoder().decode(Avatar3DModel.self, from: data) {
            print("✅ [Avatar3DPersistence] Loaded 3D avatar from UserDefaults: \(avatar.name)")
            return avatar
        }
        
        print("⚠️ [Avatar3DPersistence] No saved 3D avatar found")
        return nil
    }
    
    /// Check if a 3D avatar exists
    func has3DAvatar() -> Bool {
        return load() != nil
    }
    
    /// Delete saved 3D avatar
    func delete() {
        try? FileManager.default.removeItem(at: avatar3DURL)
        UserDefaults.standard.removeObject(forKey: avatar3DKey)
        print("🗑️ [Avatar3DPersistence] Deleted 3D avatar")
    }
    
    // MARK: - Migration from 2D System
    
    /// Check if migration from 2D avatar has been completed
    func hasMigratedFrom2D() -> Bool {
        return UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    /// Mark migration as completed
    func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
    
    /// Migrate from 2D Avatar to Avatar3DModel
    func migrateFrom2D(avatar2D: Avatar) -> Avatar3DModel {
        print("🔄 [Avatar3DPersistence] Migrating from 2D avatar: \(avatar2D.name)")
        
        let avatar3D = Avatar3DModel()
        
        // Migrate basic info
        avatar3D.name = avatar2D.name
        
        // Map personality to species and appearance
        switch avatar2D.personality {
        case .friendlyCurious:
            avatar3D.species = .human
            avatar3D.gender = .neutral
            avatar3D.facialFeatures.eyeColor = .blue
            avatar3D.facialFeatures.customEyeColor = nil
            avatar3D.hair.color = .brown
            avatar3D.hair.customColor = nil
            
        case .energeticCoach:
            avatar3D.species = .animal
            avatar3D.gender = .male
            avatar3D.facialFeatures.eyeColor = .amber
            avatar3D.facialFeatures.customEyeColor = nil
            avatar3D.hair.color = .red
            avatar3D.hair.customColor = nil
            
        case .calmReflective:
            avatar3D.species = .human
            avatar3D.gender = .female
            avatar3D.facialFeatures.eyeColor = .green
            avatar3D.facialFeatures.customEyeColor = nil
            avatar3D.hair.color = .auburn
            avatar3D.hair.customColor = nil
            avatar3D.hair.style = .long
            
        case .wisePatient:
            avatar3D.species = .human
            avatar3D.gender = .male
            avatar3D.facialFeatures.eyeColor = .gray
            avatar3D.facialFeatures.customEyeColor = nil
            avatar3D.hair.color = .white
            avatar3D.hair.customColor = nil
            avatar3D.hair.style = .short
            avatar3D.hair.facialHair = .beard
        }
        
        // Migrate voice if available
        if let voiceID = avatar2D.voiceIdentifier {
            avatar3D.voiceId = voiceID
        }
        
        print("✅ [Avatar3DPersistence] Migration complete")
        return avatar3D
    }
}

// MARK: - CloudKit Sync Preparation

struct Avatar3DCloudKitRecord {
    let id: UUID
    let name: String
    let jsonData: Data
    let lastModified: Date
    
    static func from(avatar: Avatar3DModel) throws -> Avatar3DCloudKitRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(avatar)
        
        return Avatar3DCloudKitRecord(
            id: UUID(), // In production, use avatar's stable ID
            name: avatar.name,
            jsonData: data,
            lastModified: Date()
        )
    }
}

// MARK: - Export/Import Utilities

extension Avatar3DModel {
    
    /// Export avatar to JSON string
    func exportToJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw Avatar3DExportError.encodingFailed
        }
        return json
    }
    
    /// Import avatar from JSON string
    static func importFromJSON(_ json: String) throws -> Avatar3DModel {
        guard let data = json.data(using: .utf8) else {
            throw Avatar3DExportError.invalidJSON
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Avatar3DModel.self, from: data)
    }
    
    /// Export avatar to file
    func exportToFile(at url: URL) throws {
        let json = try exportToJSON()
        try json.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Import avatar from file
    static func importFromFile(at url: URL) throws -> Avatar3DModel {
        let json = try String(contentsOf: url, encoding: .utf8)
        return try importFromJSON(json)
    }
}

enum Avatar3DExportError: LocalizedError {
    case encodingFailed
    case invalidJSON
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode avatar to JSON"
        case .invalidJSON:
            return "Invalid JSON format"
        case .fileNotFound:
            return "Avatar file not found"
        }
    }
}

// MARK: - Preview Helpers

extension Avatar3DStorageManager {
    
    /// Create a default avatar for testing
    static func createDefaultAvatar() -> Avatar3DModel {
        let avatar = Avatar3DModel()
        avatar.name = "Test Avatar"
        avatar.species = .human
        avatar.gender = .neutral
        return avatar
    }
}
