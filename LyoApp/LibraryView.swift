
import SwiftUI

struct LibraryView: View {
    @State private var selectedTab = 0
    let tabs = ["Saved", "Completed", "Started"]
    // Use canonical LibraryItem from Models.swift
    let items: [LibraryItem] = LibraryItem.sampleLibraryItems

    var body: some View {
        VStack(spacing: 0) {
            Picker("Library", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \ .self) { idx in
                    Text(tabs[idx]).tag(idx)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: DesignTokens.Spacing.md) {
                    ForEach(filteredItems) { item in
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: item.type.icon)
                                .font(.largeTitle)
                                .foregroundColor(DesignTokens.Colors.neonPurple)
                            Text(item.title)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.primary)
                            Text(item.type.displayName)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondary)
                        }
                        .padding()
                        .background(DesignTokens.Colors.glassOverlay)
                        .cornerRadius(DesignTokens.Radius.lg)
                        .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.3), radius: 8)
                    }
                }
                .padding()
            }
        }
        .background(DesignTokens.Colors.primaryBg)
    }

    var filteredItems: [LibraryItem] {
        // For demo, just return all items. In real app, filter by tab.
        items
    }

    // iconName no longer needed; use item.type.icon
}

