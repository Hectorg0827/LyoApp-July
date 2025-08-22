import Foundation
import Network

/// WebSocket client for real-time communication
final class WebSocketClient {
    private var task: URLSessionWebSocketTask?
    private let session: URLSession
    private var retries = 0
    private let maxRetries = 3
    private var isConnected = false
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket URL and start listening
    func connect(url: URL, onEvent: @escaping (Result<Data, Error>) -> Void) {
        print("🔌 Connecting to WebSocket: \(url)")
        
        task = session.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        retries = 0
        
        // Start listening for messages
        listen(onEvent: onEvent)
    }
    
    /// Disconnect and cleanup
    func disconnect() {
        print("🔌 Disconnecting WebSocket")
        isConnected = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
    
    // MARK: - Message Handling
    
    /// Listen for WebSocket messages
    private func listen(onEvent: @escaping (Result<Data, Error>) -> Void) {
        guard let task = task else { return }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                // Reset retry count on successful message
                self.retries = 0
                
                // Process the message
                self.handleMessage(message, onEvent: onEvent)
                
                // Continue listening if still connected
                if self.isConnected {
                    self.listen(onEvent: onEvent)
                }
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                onEvent(.failure(error))
                
                // Attempt reconnection if within retry limit
                self.handleConnectionError(error, onEvent: onEvent)
            }
        }
    }
    
    /// Handle incoming WebSocket message
    private func handleMessage(_ message: URLSessionWebSocketTask.Message, onEvent: @escaping (Result<Data, Error>) -> Void) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8) {
                onEvent(.success(data))
            } else {
                onEvent(.failure(WebSocketError.invalidTextMessage))
            }
            
        case .data(let data):
            onEvent(.success(data))
            
        @unknown default:
            onEvent(.failure(WebSocketError.unknownMessageType))
        }
    }
    
    /// Handle connection errors and attempt reconnection
    private func handleConnectionError(_ error: Error, onEvent: @escaping (Result<Data, Error>) -> Void) {
        retries += 1
        
        if retries <= maxRetries {
            print("🔄 WebSocket retry attempt \(retries)/\(maxRetries)")
            
            // Exponential backoff
            let delay = min(pow(2.0, Double(retries)), 30.0)
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isConnected else { return }
                
                // Attempt to reconnect
                if let url = self.task?.originalRequest?.url {
                    self.connect(url: url, onEvent: onEvent)
                }
            }
        } else {
            print("❌ WebSocket max retries exceeded, giving up")
            isConnected = false
        }
    }
    
    // MARK: - Send Messages
    
    /// Send a text message
    func send(text: String) async throws {
        guard let task = task, isConnected else {
            throw WebSocketError.notConnected
        }
        
        let message = URLSessionWebSocketTask.Message.string(text)
        try await task.send(message)
    }
    
    /// Send binary data
    func send(data: Data) async throws {
        guard let task = task, isConnected else {
            throw WebSocketError.notConnected
        }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
    }
    
    // MARK: - Connection Status
    
    var connectionStatus: Bool {
        return isConnected && task != nil
    }
    
    /// Ping the server to check connection
    func ping() async throws {
        guard let task = task else {
            throw WebSocketError.notConnected
        }
        
        try await task.sendPing { error in
            if let error = error {
                print("❌ WebSocket ping failed: \(error)")
            } else {
                print("🏓 WebSocket ping successful")
            }
        }
    }
}

// MARK: - WebSocket Errors
enum WebSocketError: LocalizedError {
    case notConnected
    case invalidTextMessage
    case unknownMessageType
    case connectionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidTextMessage:
            return "Unable to convert text message to data"
        case .unknownMessageType:
            return "Received unknown message type"
        case .connectionFailed(let reason):
            return "WebSocket connection failed: \(reason)"
        }
    }
}

// MARK: - WebSocket Connection Helper
extension WebSocketClient {
    
    /// Connect with authentication headers
    func connectWithAuth(url: URL, authManager: AuthManager, onEvent: @escaping (Result<Data, Error>) -> Void) async {
        var urlRequest = URLRequest(url: url)
        
        // Add authentication if available
        await authManager.authorize(&urlRequest)
        
        task = session.webSocketTask(with: urlRequest)
        task?.resume()
        isConnected = true
        retries = 0
        
        listen(onEvent: onEvent)
    }
}