import Foundation

// MARK: - Download Status Enum
/// Represents the various states of a download operation
enum DownloadStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case downloading = "downloading" 
    case completed = "completed"
    case failed = "failed"
    case paused = "paused"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .downloading:
            return "Downloading"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .paused:
            return "Paused"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .downloading, .pending:
            return true
        default:
            return false
        }
    }
    
    var isCompleted: Bool {
        self == .completed
    }
    
    var isFailed: Bool {
        switch self {
        case .failed, .cancelled:
            return true
        default:
            return false
        }
    }
}
