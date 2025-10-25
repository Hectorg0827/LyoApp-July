import Foundation

// MARK: - Backend Connection Tester
/// Utility to test if your backend is properly configured and running
class BackendConnectionTester {
    
    // Test all possible backend URLs
    static func testAllBackendConnections() async {
        print("🔍 Testing Backend Connections...")
        print("=" * 50)
        
        let testURLs = [
            "http://127.0.0.1:8000/health",
            "http://localhost:8000/health", 
            "http://127.0.0.1:8000/api/v1/health",
            "http://localhost:8000/api/v1/health",
            APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "/health")
        ]
        
        for url in testURLs {
            await testSingleURL(url)
        }
        
        print("=" * 50)
        print("🏁 Backend connection test completed")
    }
    
    private static func testSingleURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        do {
            let request = URLRequest(url: url, timeoutInterval: 5.0)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusIcon = httpResponse.statusCode == 200 ? "✅" : "⚠️"
                print("\(statusIcon) \(urlString) - Status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response: \(responseString.prefix(100))...")
                }
            }
        } catch {
            print("❌ \(urlString) - Error: \(error.localizedDescription)")
        }
    }
    
    // Quick test for your main API configuration
    static func quickConfigTest() {
        print("📋 Current API Configuration:")
        print("   Base URL: \(APIConfig.baseURL)")
        print("   WebSocket URL: \(APIConfig.webSocketURL)")
        print("   Use Mock Data: \(DevelopmentConfig.useMockData)")
        print("   Is Production: \(APIConfig.isProduction)")
        print("   Debug Logging: \(DevelopmentConfig.enableDebugLogging)")
    }
}

// MARK: - String Extension for Pretty Printing
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}