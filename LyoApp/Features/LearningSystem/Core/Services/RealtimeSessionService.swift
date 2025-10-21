import Foundation
import Combine

/// Real-time WebSocket service for adaptive learning sessions
/// Implements bidirectional communication with backend policy engine
class RealtimeSessionService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var connectionState: ConnectionState = .disconnected
    @Published var currentALO: ALO?
    @Published var sessionEnded: Bool = false
    @Published var sessionSummary: [String: Any]?
    @Published var error: SessionError?

    // MARK: - Private Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    private let sessionId: UUID
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    // MARK: - Telemetry

    private var signalStartTime: Date?
    private var hintsUsedCount = 0

    // MARK: - Initialization

    init(sessionId: UUID) {
        self.sessionId = sessionId
        super.init()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    func connect() {
        guard connectionState != .connected else {
            print("⚠️ [WebSocket] Already connected")
            return
        }

        connectionState = .connecting

        #if DEBUG
        let baseURL = "ws://localhost:8000/api/v1"
        #else
        let baseURL = "wss://api.lyoapp.com/api/v1"
        #endif

        guard let url = URL(string: "\(baseURL)/sessions/\(sessionId)/run") else {
            error = .invalidURL
            return
        }

        var request = URLRequest(url: url)
        // TODO: Add auth token to headers or query params

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        connectionState = .connected
        print("🔌 [WebSocket] Connecting to session: \(sessionId)")

        // Start receiving messages
        receiveMessage()

        // Start heartbeat
        startHeartbeat()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        pingTimer?.invalidate()
        pingTimer = nil
        connectionState = .disconnected
        print("🔌 [WebSocket] Disconnected")
    }

    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            error = .maxReconnectAttemptsReached
            connectionState = .disconnected
            return
        }

        reconnectAttempts += 1
        connectionState = .reconnecting

        print("🔄 [WebSocket] Reconnecting... attempt \(reconnectAttempts)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }

    // MARK: - Message Handling

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text: text)
                    }
                @unknown default:
                    break
                }

                // Continue receiving
                self.receiveMessage()

            case .failure(let error):
                print("❌ [WebSocket] Receive error: \(error)")
                self.handleDisconnection()
            }
        }
    }

    private func handleMessage(text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            // Parse message type
            let typeContainer = try JSONDecoder().decode(MessageType.self, from: data)

            switch typeContainer.type {
            case "alo":
                handleALOMessage(data: data)
            case "next":
                handleNextMessage(data: data)
            case "end":
                handleEndMessage(data: data)
            default:
                print("⚠️ [WebSocket] Unknown message type: \(typeContainer.type)")
            }

        } catch {
            print("❌ [WebSocket] Failed to parse message: \(error)")
        }
    }

    private func handleALOMessage(data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(ALOMessageResponse.self, from: data)

            DispatchQueue.main.async {
                self.currentALO = message.alo
                self.signalStartTime = Date()
                self.hintsUsedCount = 0
                print("📥 [WebSocket] Received ALO: \(message.alo.id) (type=\(message.alo.aloType))")
            }

        } catch {
            print("❌ [WebSocket] Failed to decode ALO message: \(error)")
        }
    }

    private func handleNextMessage(data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(NextMessageResponse.self, from: data)

            DispatchQueue.main.async {
                if let alo = message.alo {
                    self.currentALO = alo
                    self.signalStartTime = Date()
                    self.hintsUsedCount = 0
                    print("📥 [WebSocket] Next ALO: \(alo.id) | reason: \(message.reason ?? "advance")")
                } else {
                    print("⚠️ [WebSocket] No next ALO - session may be ending")
                }
            }

        } catch {
            print("❌ [WebSocket] Failed to decode next message: \(error)")
        }
    }

    private func handleEndMessage(data: Data) {
        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(SessionEndMessageResponse.self, from: data)

            DispatchQueue.main.async {
                self.sessionEnded = true
                self.sessionSummary = message.summary.mapValues { $0.value }
                print("🏁 [WebSocket] Session ended: \(message.summary)")
            }

            disconnect()

        } catch {
            print("❌ [WebSocket] Failed to decode end message: \(error)")
        }
    }

    private func handleDisconnection() {
        DispatchQueue.main.async {
            if self.connectionState == .connected {
                self.reconnect()
            }
        }
    }

    // MARK: - Sending Signals

    /// Send a signal to the backend policy engine
    func sendSignal(aloId: UUID, event: SignalEvent, correct: Bool? = nil, payload: [String: Any]? = nil) {
        guard connectionState == .connected else {
            print("⚠️ [WebSocket] Not connected, cannot send signal")
            return
        }

        // Calculate latency
        let latencyMs: Int?
        if let startTime = signalStartTime {
            latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        } else {
            latencyMs = nil
        }

        let signal = SignalMessageRequest(
            aloId: aloId,
            event: event.rawValue,
            correct: correct,
            latencyMs: latencyMs,
            hintsUsed: hintsUsedCount,
            payload: payload?.mapValues { AnyCodable($0) }
        )

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(signal)
            let message = URLSessionWebSocketTask.Message.data(data)

            webSocketTask?.send(message) { error in
                if let error = error {
                    print("❌ [WebSocket] Send error: \(error)")
                } else {
                    print("📤 [WebSocket] Signal sent: event=\(event), correct=\(correct ?? false), latency=\(latencyMs ?? 0)ms")
                }
            }

        } catch {
            print("❌ [WebSocket] Failed to encode signal: \(error)")
        }
    }

    /// Increment hints used (for telemetry)
    func incrementHints() {
        hintsUsedCount += 1
        print("💡 [Telemetry] Hints used: \(hintsUsedCount)")
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("❌ [WebSocket] Ping failed: \(error)")
                self?.handleDisconnection()
            }
        }
    }

    // MARK: - Supporting Types

    struct MessageType: Codable {
        let type: String
    }

    enum SignalEvent: String {
        case answered
        case completed
        case helpRequested = "help_requested"
        case skipped
    }

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error

        var displayName: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .reconnecting: return "Reconnecting..."
            case .error: return "Error"
            }
        }
    }

    enum SessionError: LocalizedError {
        case invalidURL
        case connectionFailed
        case maxReconnectAttemptsReached
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid WebSocket URL"
            case .connectionFailed:
                return "Failed to connect to session"
            case .maxReconnectAttemptsReached:
                return "Maximum reconnection attempts reached"
            case .decodingError(let message):
                return "Failed to decode message: \(message)"
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension RealtimeSessionService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectAttempts = 0
            print("✅ [WebSocket] Connection established")
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            print("🔌 [WebSocket] Connection closed: \(closeCode)")
        }
    }
}
