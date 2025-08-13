//
//  FuturisticHeaderView_Fixed.swift
//  LyoApp
//
//  Clean replacement for problematic FuturisticHeaderView
//

import SwiftUI
import Combine

struct FuturisticHeaderView: View {
    @State private var isDrawerExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Simplified header placeholder
            HStack {
                Button(action: {
                    isDrawerExpanded.toggle()
                }) {
                    Text("Lyo")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.brand)
                        )
                }
                
                Spacer()
                
                if isDrawerExpanded {
                    HStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignTokens.Colors.brand)
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.brand)
                        Image(systemName: "books.vertical")
                            .foregroundColor(DesignTokens.Colors.brand)
                    }
                }
            }
            .padding(.horizontal)
            
            if isDrawerExpanded {
                // Simplified stories section
                Text("Stories Section")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding()
            }
        }
        .animation(.easeInOut, value: isDrawerExpanded)
    }
}

#Preview {
    FuturisticHeaderView()
        .background(Color.black.ignoresSafeArea())
}
