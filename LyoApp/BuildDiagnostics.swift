import Foundation

// MARK: - Build Diagnostics
// File created to force compilation ordering and provide visibility when certain symbols are missing.
// Will log presence of key types at runtime (debug only) and ensure they are part of the target.

#if DEBUG
struct BuildDiagnostics {
    static func verify() {
        // Touch types to guarantee linkage
        _ = SystemHealthResponse.mock()
        _ = GlobalModels.DisplayMode.allCases.count
        print("[BuildDiagnostics] SystemHealthResponse & DisplayMode reachable.")
    }
}
#endif
