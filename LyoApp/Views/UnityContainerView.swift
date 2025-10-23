import SwiftUI
import UIKit

/// SwiftUI view that contains the Unity render view
struct UnityContainerView: View {
    @State private var isUnityReady = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            if !UnityBridge.shared.isAvailable() {
                // Unity not integrated
                UnityNotAvailableView()
            } else if isUnityReady {
                // Unity is loaded and ready
                UnityViewRepresentable()
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Unity is loading
                UnityLoadingView()
            }
        }
        .onAppear {
            initializeUnity()
        }
        .onDisappear {
            pauseUnity()
        }
        .alert("Unity Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func initializeUnity() {
        guard UnityBridge.shared.isAvailable() else {
            print("⚠️ Unity not available - framework not integrated")
            return
        }
        
        print("🎮 Initializing Unity...")
        UnityBridge.shared.initializeUnity()
        
        // Give Unity time to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isUnityReady = true
            UnityBridge.shared.resumeUnity()
            print("✅ Unity ready to display")
        }
    }
    
    private func pauseUnity() {
        if UnityBridge.shared.isAvailable() {
            UnityBridge.shared.pauseUnity()
        }
    }
}

/// UIViewRepresentable wrapper for Unity's UIView
struct UnityViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        // Get Unity's view or return placeholder
        if let unityView = UnityBridge.shared.getUnityView() {
            print("✅ Unity view obtained successfully")
            return unityView
        } else {
            print("⚠️ Could not get Unity view, showing placeholder")
            return createPlaceholderView()
        }
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Unity manages its own view updates
    }
    
    private func createPlaceholderView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Unity View Not Available"
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
}

/// Loading view shown while Unity initializes
struct UnityLoadingView: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Unity logo/icon
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animationAmount))
                
                Image(systemName: "cube.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animationAmount = 360
                }
            }
            
            Text("Loading 3D Experience...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Unity Engine Initializing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// View shown when Unity is not integrated
struct UnityNotAvailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Unity Not Integrated")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The Unity framework has not been integrated into this build.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("To enable Unity:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top, spacing: 8) {
                    Text("1.")
                        .foregroundColor(.secondary)
                    Text("Export Unity project from Unity Editor")
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Text("2.")
                        .foregroundColor(.secondary)
                    Text("Run integrate_unity.sh script")
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Text("3.")
                        .foregroundColor(.secondary)
                    Text("Rebuild the app")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    UnityContainerView()
}

#Preview("Loading") {
    UnityLoadingView()
}

#Preview("Not Available") {
    UnityNotAvailableView()
}
