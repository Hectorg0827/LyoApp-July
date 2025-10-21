import SwiftUI
import UIKit
import os.log

// MARK: - Safe Asset Manager with Fallback System
class SafeAssetManager: ObservableObject {
    static let shared = SafeAssetManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "SafeAssetManager")
    
    // Cache for checked assets
    private var assetCache: [String: Bool] = [:]
    private var imageCache: [String: UIImage] = [:]
    
    private init() {
        logger.info("✅ SafeAssetManager initialized")
        preloadCriticalAssets()
    }
    
    // MARK: - SF Symbol Fallback System
    
    /// Get SF Symbol with fallback for missing symbols
    func safeSystemImage(_ symbolName: String, fallback: String? = nil) -> Image {
        if isSystemImageAvailable(symbolName) {
            return Image(systemName: symbolName)
        } else {
            let fallbackSymbol = fallback ?? getFallbackSymbol(for: symbolName)
            logger.warning("⚠️ SF Symbol '\(symbolName)' not available, using fallback: '\(fallbackSymbol)'")
            return Image(systemName: fallbackSymbol)
        }
    }
    
    /// Check if SF Symbol exists
    private func isSystemImageAvailable(_ symbolName: String) -> Bool {
        if let cached = assetCache[symbolName] {
            return cached
        }
        
        let isAvailable = UIImage(systemName: symbolName) != nil
        assetCache[symbolName] = isAvailable
        
        if !isAvailable {
            logger.info("🔍 SF Symbol check: '\(symbolName)' - NOT FOUND")
        }
        
        return isAvailable
    }
    
    /// Get appropriate fallback symbol
    private func getFallbackSymbol(for originalSymbol: String) -> String {
        // Map problematic symbols to safe fallbacks
        let fallbackMap: [String: String] = [
            // Brain-related symbols
            "brain.filled": "brain",
            "brain.head.profile": "person.circle",
            "brain.head.profile.fill": "person.circle.fill",
            
            // Certificate symbols
            "certificate.fill": "award.fill",
            "certificate": "award",
            "medal.fill": "star.circle.fill",
            
            // AI/Learning symbols
            "lightbulb.max.fill": "lightbulb.fill",
            "graduationcap.fill": "book.fill",
            "person.badge.plus.fill": "person.crop.circle.badge.plus",
            
            // Generic fallbacks
            "checkmark.circle.trianglebadge.exclamationmark": "exclamationmark.triangle",
            "person.crop.rectangle.stack.fill": "person.3.fill"
        ]
        
        return fallbackMap[originalSymbol] ?? "questionmark.circle"
    }
    
    // MARK: - Asset Image Fallback System
    
    /// Get asset image with fallback
    func safeAssetImage(_ imageName: String) -> Image {
        if let uiImage = getUIImageSafely(imageName) {
            return Image(uiImage: uiImage)
        } else {
            logger.warning("⚠️ Asset image '\(imageName)' not found, using fallback")
            return getFallbackImage(for: imageName)
        }
    }
    
    /// Get UIImage safely with caching
    private func getUIImageSafely(_ imageName: String) -> UIImage? {
        // Check cache first
        if let cached = imageCache[imageName] {
            return cached
        }
        
        // Try to load from bundle
        let image = UIImage(named: imageName)
        
        if let image = image {
            imageCache[imageName] = image
            logger.debug("✅ Asset image loaded: '\(imageName)'")
        } else {
            logger.info("🔍 Asset image check: '\(imageName)' - NOT FOUND")
            imageCache[imageName] = UIImage() // Cache the fact that it's missing
        }
        
        return image
    }
    
    /// Get fallback image for missing assets
    private func getFallbackImage(for imageName: String) -> Image {
        let fallbackMap: [String: String] = [
            // Avatar images
            "suddy_buddy_avatar": "person.circle.fill",
            "default_avatar": "person.circle.fill",
            "user_avatar": "person.crop.circle.fill",
            
            // App icons
            "app_icon": "app.fill",
            "logo": "sparkles",
            
            // Course/Learning images
            "course_placeholder": "book.fill",
            "lesson_icon": "graduationcap.fill",
            
            // Generic placeholders
            "placeholder_image": "photo.fill",
            "default_image": "rectangle.fill"
        ]
        
        if let systemSymbol = fallbackMap[imageName] {
            return Image(systemName: systemSymbol)
        } else {
            // Ultimate fallback
            return Image(systemName: "photo")
        }
    }
    
    // MARK: - Preloading Critical Assets
    
    private func preloadCriticalAssets() {
        logger.info("🔄 Preloading critical assets...")
        
        // Critical SF Symbols to check
        let criticalSymbols = [
            "brain.filled",
            "certificate.fill",
            "person.crop.circle.fill",
            "house.fill",
            "book.fill",
            "person.fill",
            "gear",
            "plus.circle.fill",
            "heart.fill",
            "message.fill"
        ]
        
        // Critical asset images to check
        let criticalAssets = [
            "suddy_buddy_avatar",
            "app_icon",
            "logo",
            "default_avatar"
        ]
        
        // Check SF Symbols
        for symbol in criticalSymbols {
            _ = isSystemImageAvailable(symbol)
        }
        
        // Check asset images
        for asset in criticalAssets {
            _ = getUIImageSafely(asset)
        }
        
        logger.info("✅ Asset preloading completed")
    }
    
    // MARK: - Asset Validation Methods
    
    /// Validate all assets and report issues
    func validateAllAssets() -> AssetValidationReport {
        logger.info("🔍 Starting comprehensive asset validation...")
        
        var missingSymbols: [String] = []
        var missingImages: [String] = []
        var availableSymbols: [String] = []
        var availableImages: [String] = []
        
        // Check SF Symbols
        let allSymbolsToCheck = [
            "brain.filled", "certificate.fill", "brain.head.profile", "brain.head.profile.fill",
            "medal.fill", "lightbulb.max.fill", "graduationcap.fill",
            "person.badge.plus.fill", "checkmark.circle.trianglebadge.exclamationmark"
        ]
        
        for symbol in allSymbolsToCheck {
            if isSystemImageAvailable(symbol) {
                availableSymbols.append(symbol)
            } else {
                missingSymbols.append(symbol)
            }
        }
        
        // Check asset images
        let allImagesToCheck = [
            "suddy_buddy_avatar", "default_avatar", "user_avatar",
            "app_icon", "logo", "course_placeholder", "lesson_icon"
        ]
        
        for imageName in allImagesToCheck {
            if getUIImageSafely(imageName) != nil {
                availableImages.append(imageName)
            } else {
                missingImages.append(imageName)
            }
        }
        
        let report = AssetValidationReport(
            missingSymbols: missingSymbols,
            missingImages: missingImages,
            availableSymbols: availableSymbols,
            availableImages: availableImages
        )
        
        logger.info("📊 Asset validation completed: \(missingSymbols.count) missing symbols, \(missingImages.count) missing images")
        
        return report
    }
    
    // MARK: - Utility Methods
    
    /// Clear asset caches (useful for testing)
    func clearCaches() {
        assetCache.removeAll()
        imageCache.removeAll()
        logger.info("🗑️ Asset caches cleared")
    }
    
    /// Get cache statistics
    var cacheStats: (symbols: Int, images: Int) {
        return (assetCache.count, imageCache.count)
    }
}

// MARK: - Asset Validation Report
struct AssetValidationReport {
    let missingSymbols: [String]
    let missingImages: [String]
    let availableSymbols: [String]
    let availableImages: [String]
    
    var hasMissingAssets: Bool {
        return !missingSymbols.isEmpty || !missingImages.isEmpty
    }
    
    var summary: String {
        let totalMissing = missingSymbols.count + missingImages.count
        let totalAvailable = availableSymbols.count + availableImages.count
        return "Assets: \(totalAvailable) available, \(totalMissing) missing (with fallbacks)"
    }
    
    var detailedReport: String {
        var report = "=== Asset Validation Report ===\n"
        
        if !missingSymbols.isEmpty {
            report += "\n❌ Missing SF Symbols:\n"
            for symbol in missingSymbols {
                report += "  • \(symbol)\n"
            }
        }
        
        if !missingImages.isEmpty {
            report += "\n❌ Missing Asset Images:\n"
            for image in missingImages {
                report += "  • \(image)\n"
            }
        }
        
        if !availableSymbols.isEmpty {
            report += "\n✅ Available SF Symbols:\n"
            for symbol in availableSymbols {
                report += "  • \(symbol)\n"
            }
        }
        
        if !availableImages.isEmpty {
            report += "\n✅ Available Asset Images:\n"
            for image in availableImages {
                report += "  • \(image)\n"
            }
        }
        
        report += "\n" + summary
        return report
    }
}

// MARK: - SwiftUI Extensions for Safe Asset Usage
extension Image {
    /// Create image with automatic fallback
    static func safeSystemImage(_ symbolName: String, fallback: String? = nil) -> Image {
        return SafeAssetManager.shared.safeSystemImage(symbolName, fallback: fallback)
    }
    
    /// Create asset image with automatic fallback
    static func safeAsset(_ imageName: String) -> Image {
        return SafeAssetManager.shared.safeAssetImage(imageName)
    }
}

// MARK: - Convenience View Modifiers
extension View {
    /// Apply safe asset validation and show warnings in debug builds
    func safeAssets() -> some View {
        self.onAppear {
            #if DEBUG
            let report = SafeAssetManager.shared.validateAllAssets()
            if report.hasMissingAssets {
                print("⚠️ ASSET WARNING: Some assets are missing and using fallbacks")
                print(report.detailedReport)
            }
            #endif
        }
    }
}