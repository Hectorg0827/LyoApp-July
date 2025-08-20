import SwiftUI
import UIKit

// MARK: - App Store Screenshot Generator
/// Professional screenshot generator for Lyo app iOS submission
struct AppStoreScreenshotGeneratorClassic: View {
    let deviceType: ScreenshotDeviceType
    @State private var animateElements = false
    
    enum ScreenshotDeviceType: String, CaseIterable {
        case iPhone67 = "iPhone 6.7\""  // iPhone 14 Pro Max, 15 Pro Max
        case iPhone65 = "iPhone 6.5\""  // iPhone XS Max, 11 Pro Max, 12 Pro Max, 13 Pro Max
        case iPhone55 = "iPhone 5.5\""  // iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus
        case iPadPro129 = "iPad Pro 12.9\""
        case iPadPro11 = "iPad Pro 11\""
        
        var size: CGSize {
            switch self {
            case .iPhone67: return CGSize(width: 1290, height: 2796)
            case .iPhone65: return CGSize(width: 1242, height: 2688)
            case .iPhone55: return CGSize(width: 1242, height: 2208)
            case .iPadPro129: return CGSize(width: 2048, height: 2732)
            case .iPadPro11: return CGSize(width: 1668, height: 2388)
            }
        }
        
        var displayName: String {
            return rawValue
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching app
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 40) {
                // Header with Lyo branding
                headerSection
                
                // Feature showcase
                featureShowcaseSection
                
                // Bottom CTA
                callToActionSection
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 80)
        }
        .frame(width: deviceType.size.width, height: deviceType.size.height)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                animateElements = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 30) {
            // Quantum Lyo logo
            ZStack {
                // Quantum rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.8),
                                    Color.cyan.opacity(0.3),
                                    Color.cyan.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(
                            width: CGFloat(100 + ring * 30),
                            height: CGFloat(100 + ring * 30)
                        )
                        .scaleEffect(animateElements ? 1.0 : 0.8)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.8).delay(Double(ring) * 0.2), value: animateElements)
                }
                
                // Central "Lyo" text
                Text("Lyo")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.cyan,
                                Color.white
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                    .scaleEffect(animateElements ? 1.0 : 0.0)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: animateElements)
            }
            
            // App tagline
            VStack(spacing: 12) {
                Text("AI-Powered Learning Hub")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: animateElements)
                
                Text("Discover, Learn, and Grow with Intelligent Personalization")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.cyan.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
            }
        }
    }
    
    // MARK: - Feature Showcase
    private var featureShowcaseSection: some View {
        VStack(spacing: 40) {
            // Main feature grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 40) {
                FeatureHighlightCard(
                    icon: "brain.head.profile",
                    title: "Smart AI Assistant",
                    description: "Get personalized recommendations and instant answers",
                    color: .cyan,
                    animateElements: $animateElements,
                    delay: 1.2
                )
                
                FeatureHighlightCard(
                    icon: "magnifyingglass.circle.fill",
                    title: "Intelligent Search",
                    description: "Find exactly what you need with AI-powered search",
                    color: .blue,
                    animateElements: $animateElements,
                    delay: 1.4
                )
                
                FeatureHighlightCard(
                    icon: "rectangle.grid.3x2.fill",
                    title: "Netflix-Style Discovery",
                    description: "Beautiful interface designed for seamless learning",
                    color: .purple,
                    animateElements: $animateElements,
                    delay: 1.6
                )
                
                FeatureHighlightCard(
                    icon: "graduationcap.fill",
                    title: "University Courses",
                    description: "Access courses from Harvard, MIT, Stanford and more",
                    color: .green,
                    animateElements: $animateElements,
                    delay: 1.8
                )
            }
        }
    }
    
    // MARK: - Call to Action
    private var callToActionSection: some View {
        VStack(spacing: 20) {
            Text("Start Your Learning Journey Today")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(2.0), value: animateElements)
            
            HStack(spacing: 30) {
                StatBadge(number: "500+", label: "University Courses", delay: 2.2)
                StatBadge(number: "50K+", label: "Video Lessons", delay: 2.4)
                StatBadge(number: "10K+", label: "E-Books", delay: 2.6)
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8).delay(2.8), value: animateElements)
        }
    }
}

// MARK: - Feature Highlight Card
struct FeatureHighlightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @Binding var animateElements: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(color)
            }
            .scaleEffect(animateElements ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateElements)
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(delay + 0.2), value: animateElements)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(animateElements ? 1.0 : 0.95)
        .animation(.easeOut(duration: 0.8).delay(delay), value: animateElements)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let number: String
    let label: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.cyan)
                .scaleEffect(animate ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animate)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.8).delay(delay + 0.2), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Screenshot Export Utility
struct ScreenshotExportView: View {
    @State private var selectedDevice: AppStoreScreenshotGeneratorClassic.ScreenshotDeviceType = .iPhone67
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Device selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Device Type")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(AppStoreScreenshotGeneratorClassic.ScreenshotDeviceType.allCases, id: \.self) { device in
                            Button {
                                selectedDevice = device
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: device == .iPadPro129 || device == .iPadPro11 ? "ipad" : "iphone")
                                        .font(.system(size: 24))
                                    
                                    Text(device.displayName)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("\(Int(device.size.width))×\(Int(device.size.height))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedDevice == device ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedDevice == device ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    AppStoreScreenshotGeneratorClassic(deviceType: selectedDevice)
                        .scaleEffect(0.15)
                        .frame(
                            width: selectedDevice.size.width * 0.15,
                            height: selectedDevice.size.height * 0.15
                        )
                        .clipped()
                        .background(Color.black)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
                
                // Export button
                Button {
                    exportScreenshot()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        
                        Text(isExporting ? "Exporting..." : "Export Screenshot")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                
                Spacer()
            }
            .padding()
            .navigationTitle("App Store Screenshots")
        }
    }
    
    private func exportScreenshot() {
        isExporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // In a real implementation, this would export the screenshot
            // For now, we'll just simulate the export process
            isExporting = false
        }
    }
}

// MARK: - Preview
#Preview("iPhone 6.7\" Screenshot") {
    AppStoreScreenshotGeneratorClassic(deviceType: .iPhone67)
        .scaleEffect(0.3)
}

#Preview("iPad Pro 12.9\" Screenshot") {
    AppStoreScreenshotGeneratorClassic(deviceType: .iPadPro129)
        .scaleEffect(0.25)
}

#Preview("Screenshot Export Tool") {
    ScreenshotExportView()
}
