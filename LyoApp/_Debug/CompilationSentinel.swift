// CompilationSentinel.swift
// Forces the compiler to resolve key canonical symbols to catch configuration issues early.

import Foundation
import SwiftUI

// Import the canonical SystemHealthResponse
// This file deliberately references the canonical models/enums without pulling in UI frameworks
// to ensure they are part of the target's Sources build phase.

@discardableResult
func _compilationSentinelReferences() -> Int {
    // Reference SystemHealthResponse
    let health = SystemHealthResponse.mock()
    // Reference DisplayMode (iterate cases indirectly if available)
    let modesCount: Int
    #if canImport(SwiftUI)
    // If SwiftUI is available, just count; otherwise fallback.
    modesCount = GlobalModels.DisplayMode.allCases.count
    #else
    modesCount = 0 // Fallback; still ensures the symbol is looked up.
    _ = GlobalModels.DisplayMode.grid // Touch one case explicitly
    #endif
    // services is optional in SystemHealthResponse; default to 0 if nil
    // Safely unwrap optional services dictionary
    let servicesCount = health.services.map { $0.count } ?? 0
    return servicesCount + modesCount
}

// Lazy wrapper so the sentinel can be triggered explicitly without executing top-level code.
enum CompilationSentinel {
    static let value: Int = _compilationSentinelReferences()
}
