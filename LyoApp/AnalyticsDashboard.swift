import SwiftUI

// MARK: - Analytics Dashboard (Development Tool)

struct AnalyticsDashboardView: View {
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @State private var showingEventDetails = false
    @State private var selectedEvent: AnalyticsEvent?
    @State private var filterType = "All"
    
    private let eventTypes = ["All", "session", "screen_view", "tab_switch", "course", "quiz", "ai_chat", "feed", "search", "performance", "error"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Controls
                controlsSection
                
                // Analytics Overview
                overviewSection
                
                // Event Log
                eventLogSection
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Events", action: exportEvents)
                        Button("Clear Events", action: clearEvents)
                        Button(analyticsManager.debugMode ? "Disable Debug" : "Enable Debug") {
                            analyticsManager.debugMode.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Status:")
                    .font(DesignTokens.Typography.bodyMedium)
                
                Circle()
                    .fill(analyticsManager.isEnabled ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(analyticsManager.isEnabled ? "Enabled" : "Disabled")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(analyticsManager.isEnabled ? .green : .red)
                
                Spacer()
                
                Toggle("Debug Mode", isOn: $analyticsManager.debugMode)
                    .font(DesignTokens.Typography.caption)
            }
            
            // Event Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(eventTypes, id: \.self) { type in
                        Button(type) {
                            filterType = type
                        }
                        .font(DesignTokens.Typography.caption)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(filterType == type ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                        )
                        .foregroundColor(filterType == type ? .white : DesignTokens.Colors.textPrimary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
    }
    
    private var overviewSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.md) {
            MetricCard(title: "Session Events", value: "12", icon: "clock", color: .blue)
            MetricCard(title: "User Actions", value: "45", icon: "hand.tap", color: .green)
            MetricCard(title: "Performance", value: "Good", icon: "speedometer", color: .orange)
            MetricCard(title: "Errors", value: "0", icon: "exclamationmark.triangle", color: .red)
            MetricCard(title: "API Calls", value: "23", icon: "network", color: .purple)
            MetricCard(title: "Cache Hits", value: "89%", icon: "memorychip", color: .indigo)
        }
        .padding(DesignTokens.Spacing.md)
    }
    
    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Recent Events")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("Live")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.green)
                
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .scaleEffect(1.5)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: analyticsManager.isEnabled)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.xs) {
                    // Mock events for demonstration
                    ForEach(mockEvents.filter { event in
                        filterType == "All" || event.name.contains(filterType)
                    }, id: \.name) { event in
                        EventRowView(event: event) {
                            selectedEvent = event
                            showingEventDetails = true
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
    }
    
    private func exportEvents() {
        // Export functionality would go here
        print("📊 Exporting analytics events...")
    }
    
    private func clearEvents() {
        // Clear events functionality would go here
        print("📊 Clearing analytics events...")
    }
    
    // Mock events for demonstration
    private var mockEvents: [AnalyticsEvent] {
        [
            AnalyticsEvent(name: "screen_view", parameters: ["screen_name": "Learn", "timestamp": Date()]),
            AnalyticsEvent(name: "course_start", parameters: ["topic": "Swift Programming", "difficulty": "intermediate"]),
            AnalyticsEvent(name: "quiz_complete", parameters: ["score": 8, "total_questions": 10, "accuracy": 0.8]),
            AnalyticsEvent(name: "ai_chat_start", parameters: ["topic": "Swift Programming", "chapter_title": "Introduction"]),
            AnalyticsEvent(name: "tab_switch", parameters: ["from_tab": "learn", "to_tab": "feed"]),
            AnalyticsEvent(name: "performance_metric", parameters: ["view_name": "FeedManager", "load_time": 0.5, "memory_usage": 1024]),
            AnalyticsEvent(name: "search", parameters: ["query": "iOS development", "result_count": 15, "search_time": 0.3])
        ]
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(value)
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct EventRowView: View {
    let event: AnalyticsEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Event Icon
                Circle()
                    .fill(eventColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: eventIcon)
                            .font(.caption)
                            .foregroundColor(eventColor)
                    )
                
                // Event Details
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(event.name)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if let firstParam = event.parameters.first {
                        Text("\(firstParam.key): \(firstParam.value)")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Timestamp
                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text("Just now")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var eventColor: Color {
        switch event.name {
        case let name where name.contains("error"): return .red
        case let name where name.contains("performance"): return .orange
        case let name where name.contains("course") || name.contains("quiz"): return .blue
        case let name where name.contains("ai"): return .purple
        case let name where name.contains("search"): return .green
        default: return .gray
        }
    }
    
    private var eventIcon: String {
        switch event.name {
        case let name where name.contains("screen"): return "rectangle.stack"
        case let name where name.contains("course"): return "graduationcap"
        case let name where name.contains("quiz"): return "questionmark.circle"
        case let name where name.contains("ai"): return "brain.head.profile"
        case let name where name.contains("search"): return "magnifyingglass"
        case let name where name.contains("performance"): return "speedometer"
        case let name where name.contains("error"): return "exclamationmark.triangle"
        default: return "circle"
        }
    }
}

struct EventDetailView: View {
    let event: AnalyticsEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Event Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text(event.name)
                            .font(DesignTokens.Typography.title1)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Event Details")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    // Parameters
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Parameters")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        ForEach(Array(event.parameters.keys), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(event.parameters[key] ?? "nil")")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            .padding(DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(DesignTokens.Colors.glassBg)
                            )
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Event Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Make AnalyticsEvent Identifiable for sheet presentation
extension AnalyticsEvent: Identifiable {
    var id: String {
        "\(name)_\(timestamp?.timeIntervalSince1970 ?? 0)"
    }
}
