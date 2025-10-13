//
//  ClothingCustomizationViews.swift
//  LyoApp
//
//  Comprehensive clothing and accessory customization
//  Outfit presets, individual pieces, accessories
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Main Clothing Selection View

struct ClothingSelectionView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Quick Outfit Presets
            OutfitPresetsView(avatar: avatar)
            
            // Individual Clothing Pieces
            ClothingPiecesView(avatar: avatar)
        }
    }
}

// MARK: - Outfit Presets

struct OutfitPresetsView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    let outfitPresets: [(name: String, icon: String, top: ClothingItem, bottom: ClothingItem?, shoes: ClothingItem?)] = [
        (
            name: "Casual",
            icon: "tshirt.fill",
            top: ClothingItem(name: "T-Shirt", type: .top, color: .blue, pattern: nil),
            bottom: ClothingItem(name: "Jeans", type: .bottom, color: Color(red: 0.2, green: 0.3, blue: 0.5), pattern: nil),
            shoes: ClothingItem(name: "Sneakers", type: .shoes, color: .white, pattern: nil)
        ),
        (
            name: "Formal",
            icon: "suit.fill",
            top: ClothingItem(name: "Dress Shirt", type: .top, color: .white, pattern: nil),
            bottom: ClothingItem(name: "Dress Pants", type: .bottom, color: .black, pattern: nil),
            shoes: ClothingItem(name: "Dress Shoes", type: .shoes, color: .black, pattern: nil)
        ),
        (
            name: "Sporty",
            icon: "figure.run",
            top: ClothingItem(name: "Athletic Top", type: .top, color: .red, pattern: nil),
            bottom: ClothingItem(name: "Track Pants", type: .bottom, color: .black, pattern: nil),
            shoes: ClothingItem(name: "Running Shoes", type: .shoes, color: .red, pattern: nil)
        ),
        (
            name: "Cozy",
            icon: "moon.stars.fill",
            top: ClothingItem(name: "Hoodie", type: .top, color: .gray, pattern: nil),
            bottom: ClothingItem(name: "Sweatpants", type: .bottom, color: .gray, pattern: nil),
            shoes: ClothingItem(name: "Slippers", type: .shoes, color: Color(red: 0.8, green: 0.6, blue: 0.4), pattern: nil)
        ),
        (
            name: "Summer",
            icon: "sun.max.fill",
            top: ClothingItem(name: "Tank Top", type: .top, color: .yellow, pattern: nil),
            bottom: ClothingItem(name: "Shorts", type: .bottom, color: Color(red: 0.4, green: 0.6, blue: 0.8), pattern: nil),
            shoes: ClothingItem(name: "Sandals", type: .shoes, color: Color(red: 0.6, green: 0.4, blue: 0.2), pattern: nil)
        ),
        (
            name: "Winter",
            icon: "snowflake",
            top: ClothingItem(name: "Sweater", type: .top, color: Color(red: 0.5, green: 0.2, blue: 0.2), pattern: nil),
            bottom: ClothingItem(name: "Jeans", type: .bottom, color: Color(red: 0.2, green: 0.3, blue: 0.5), pattern: nil),
            shoes: ClothingItem(name: "Boots", type: .shoes, color: Color(red: 0.3, green: 0.2, blue: 0.1), pattern: nil)
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Outfits", systemImage: "sparkles")
                .font(.headline)
            
            Text("Tap a preset to dress instantly")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(outfitPresets.enumerated()), id: \.offset) { _, preset in
                        OutfitPresetCard(
                            name: preset.name,
                            icon: preset.icon,
                            topColor: preset.top.color,
                            bottomColor: preset.bottom?.color ?? .gray
                        ) {
                            withAnimation(.spring(response: 0.4)) {
                                var newClothingSet = avatar.clothing
                                newClothingSet.top = preset.top
                                newClothingSet.bottom = preset.bottom
                                newClothingSet.shoes = preset.shoes
                                avatar.clothing = newClothingSet
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct OutfitPresetCard: View {
    let name: String
    let icon: String
    let topColor: Color
    let bottomColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [topColor.opacity(0.4), bottomColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.primary)
                }
                
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Individual Clothing Pieces

struct ClothingPiecesView: View {
    @ObservedObject var avatar: Avatar3DModel
    @State private var selectedCategory: ClothingCategory = .tops
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Customize Pieces", systemImage: "slider.horizontal.3")
                .font(.headline)
            
            // Category Picker
            ClothingCategoryPicker(selectedCategory: $selectedCategory)
            
            // Clothing Items Grid
            switch selectedCategory {
            case .tops:
                ClothingItemsGrid(
                    items: topOptions,
                    selectedItem: Binding(
                        get: { avatar.clothing.top },
                        set: { 
                            var newSet = avatar.clothing
                            newSet.top = $0
                            avatar.clothing = newSet
                        }
                    )
                )
            case .bottoms:
                ClothingItemsGrid(
                    items: bottomOptions,
                    selectedItem: Binding(
                        get: { avatar.clothing.bottom },
                        set: { 
                            var newSet = avatar.clothing
                            newSet.bottom = $0
                            avatar.clothing = newSet
                        }
                    )
                )
            case .shoes:
                ClothingItemsGrid(
                    items: shoeOptions,
                    selectedItem: Binding(
                        get: { avatar.clothing.shoes },
                        set: { 
                            var newSet = avatar.clothing
                            newSet.shoes = $0
                            avatar.clothing = newSet
                        }
                    )
                )
            case .outerwear:
                ClothingItemsGrid(
                    items: outerwearOptions,
                    selectedItem: Binding(
                        get: { avatar.clothing.outerwear },
                        set: { 
                            var newSet = avatar.clothing
                            newSet.outerwear = $0
                            avatar.clothing = newSet
                        }
                    )
                )
            }
            
            // Color Picker for Selected Item
            if let selectedItem = getSelectedItem(for: selectedCategory) {
                Divider()
                    .padding(.vertical, 8)
                
                ClothingColorPicker(
                    selectedColor: Binding(
                        get: { selectedItem.color },
                        set: { newColor in
                            updateItemColor(category: selectedCategory, color: newColor)
                        }
                    ),
                    itemName: selectedItem.name
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func getSelectedItem(for category: ClothingCategory) -> ClothingItem? {
        switch category {
        case .tops: return avatar.clothing.top
        case .bottoms: return avatar.clothing.bottom
        case .shoes: return avatar.clothing.shoes
        case .outerwear: return avatar.clothing.outerwear
        }
    }
    
    private func updateItemColor(category: ClothingCategory, color: Color) {
        var newSet = avatar.clothing
        switch category {
        case .tops:
            if var item = newSet.top {
                item.color = color
                newSet.top = item
            }
        case .bottoms:
            if var item = newSet.bottom {
                item.color = color
                newSet.bottom = item
            }
        case .shoes:
            if var item = newSet.shoes {
                item.color = color
                newSet.shoes = item
            }
        case .outerwear:
            if var item = newSet.outerwear {
                item.color = color
                newSet.outerwear = item
            }
        }
        avatar.clothing = newSet
    }
    
    // Clothing Options
    private var topOptions: [ClothingItem] {
        [
            ClothingItem(name: "T-Shirt", type: .top, color: .blue, pattern: nil),
            ClothingItem(name: "Tank Top", type: .top, color: .red, pattern: nil),
            ClothingItem(name: "Polo Shirt", type: .top, color: .green, pattern: nil),
            ClothingItem(name: "Dress Shirt", type: .top, color: .white, pattern: nil),
            ClothingItem(name: "Sweater", type: .top, color: .purple, pattern: nil),
            ClothingItem(name: "Hoodie", type: .top, color: .gray, pattern: nil),
            ClothingItem(name: "Athletic Top", type: .top, color: .orange, pattern: nil),
            ClothingItem(name: "Blouse", type: .top, color: .pink, pattern: nil)
        ]
    }
    
    private var bottomOptions: [ClothingItem] {
        [
            ClothingItem(name: "Jeans", type: .bottom, color: Color(red: 0.2, green: 0.3, blue: 0.5), pattern: nil),
            ClothingItem(name: "Shorts", type: .bottom, color: Color(red: 0.4, green: 0.6, blue: 0.8), pattern: nil),
            ClothingItem(name: "Dress Pants", type: .bottom, color: .black, pattern: nil),
            ClothingItem(name: "Track Pants", type: .bottom, color: .gray, pattern: nil),
            ClothingItem(name: "Sweatpants", type: .bottom, color: Color(red: 0.5, green: 0.5, blue: 0.5), pattern: nil),
            ClothingItem(name: "Skirt", type: .bottom, color: Color(red: 0.6, green: 0.2, blue: 0.3), pattern: nil),
            ClothingItem(name: "Leggings", type: .bottom, color: .black, pattern: nil),
            ClothingItem(name: "Cargo Pants", type: .bottom, color: Color(red: 0.4, green: 0.5, blue: 0.3), pattern: nil)
        ]
    }
    
    private var shoeOptions: [ClothingItem] {
        [
            ClothingItem(name: "Sneakers", type: .shoes, color: .white, pattern: nil),
            ClothingItem(name: "Running Shoes", type: .shoes, color: .red, pattern: nil),
            ClothingItem(name: "Dress Shoes", type: .shoes, color: .black, pattern: nil),
            ClothingItem(name: "Boots", type: .shoes, color: Color(red: 0.3, green: 0.2, blue: 0.1), pattern: nil),
            ClothingItem(name: "Sandals", type: .shoes, color: Color(red: 0.6, green: 0.4, blue: 0.2), pattern: nil),
            ClothingItem(name: "Slippers", type: .shoes, color: Color(red: 0.8, green: 0.6, blue: 0.4), pattern: nil),
            ClothingItem(name: "High Tops", type: .shoes, color: .blue, pattern: nil),
            ClothingItem(name: "Loafers", type: .shoes, color: Color(red: 0.4, green: 0.25, blue: 0.15), pattern: nil)
        ]
    }
    
    private var outerwearOptions: [ClothingItem] {
        [
            ClothingItem(name: "None", type: .outerwear, color: .clear, pattern: nil),
            ClothingItem(name: "Jacket", type: .outerwear, color: .black, pattern: nil),
            ClothingItem(name: "Coat", type: .outerwear, color: Color(red: 0.3, green: 0.3, blue: 0.4), pattern: nil),
            ClothingItem(name: "Vest", type: .outerwear, color: .brown, pattern: nil),
            ClothingItem(name: "Cardigan", type: .outerwear, color: .gray, pattern: nil),
            ClothingItem(name: "Blazer", type: .outerwear, color: Color(red: 0.2, green: 0.2, blue: 0.3), pattern: nil)
        ]
    }
}

enum ClothingCategory: String, CaseIterable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case shoes = "Shoes"
    case outerwear = "Outerwear"
    
    var icon: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "figure.walk"
        case .shoes: return "shoe.fill"
        case .outerwear: return "coat.fill"
        }
    }
}

struct ClothingCategoryPicker: View {
    @Binding var selectedCategory: ClothingCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? Color.blue : Color(UIColor.tertiarySystemBackground))
                        )
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ClothingItemsGrid: View {
    let items: [ClothingItem]
    @Binding var selectedItem: ClothingItem?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 12) {
            ForEach(items, id: \.id) { item in
                ClothingItemCard(
                    item: item,
                    isSelected: selectedItem?.id == item.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedItem = item
                    }
                }
            }
        }
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? item.color.opacity(0.3) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 85)
                    
                    VStack(spacing: 4) {
                        itemIcon
                            .font(.system(size: 36))
                            .foregroundStyle(isSelected ? item.color : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Text(item.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var itemIcon: some View {
        switch item.type {
        case .top, .shirt:
            Image(systemName: "tshirt.fill")
        case .bottom, .pants:
            if item.name.contains("Skirt") {
                Image(systemName: "triangle.fill")
            } else {
                Image(systemName: "figure.walk")
            }
        case .footwear, .shoes:
            Image(systemName: "shoe.fill")
        case .outerwear, .jacket:
            if item.name == "None" {
                Image(systemName: "xmark.circle")
            } else {
                Image(systemName: "coat.fill")
            }
        case .dress:
            Image(systemName: "person.fill.viewfinder")
        case .hat:
            Image(systemName: "graduationcap.fill")
        case .scarf:
            Image(systemName: "cloud.drizzle")
        }
    }
}

struct ClothingColorPicker: View {
    @Binding var selectedColor: Color
    let itemName: String
    
    let clothingColors: [Color] = [
        // Basic colors
        .white, .black, .gray, Color(red: 0.8, green: 0.8, blue: 0.8),
        // Blues
        .blue, .cyan, Color(red: 0.2, green: 0.3, blue: 0.5),
        // Reds/Pinks
        .red, .pink, Color(red: 0.6, green: 0.2, blue: 0.3),
        // Greens
        .green, .mint, Color(red: 0.4, green: 0.5, blue: 0.3),
        // Yellows/Oranges
        .yellow, .orange, Color(red: 0.9, green: 0.7, blue: 0.3),
        // Purples
        .purple, .indigo, Color(red: 0.5, green: 0.2, blue: 0.5),
        // Browns
        .brown, Color(red: 0.4, green: 0.25, blue: 0.15), Color(red: 0.6, green: 0.4, blue: 0.2)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Color for \(itemName)", systemImage: "paintpalette.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                ForEach(Array(clothingColors.enumerated()), id: \.offset) { _, color in
                    ColorButton(
                        color: color,
                        isSelected: selectedColor.hexString == color.hexString
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Accessories Selection

struct AccessorySelectionView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Accessory Categories
            AccessoryCategoryView(
                title: "Glasses",
                icon: "eyeglasses",
                accessories: glassesOptions,
                selectedAccessories: $avatar.accessories
            )
            
            AccessoryCategoryView(
                title: "Hats",
                icon: "person.fill.viewfinder",
                accessories: hatOptions,
                selectedAccessories: $avatar.accessories
            )
            
            AccessoryCategoryView(
                title: "Jewelry",
                icon: "sparkles",
                accessories: jewelryOptions,
                selectedAccessories: $avatar.accessories
            )
            
            AccessoryCategoryView(
                title: "Other",
                icon: "bag.fill",
                accessories: otherAccessories,
                selectedAccessories: $avatar.accessories
            )
        }
    }
    
    private var glassesOptions: [Accessory] {
        [
            Accessory(name: "None", type: .glasses, color: .clear),
            Accessory(name: "Round Glasses", type: .glasses, color: .black),
            Accessory(name: "Square Glasses", type: .glasses, color: .black),
            Accessory(name: "Cat Eye Glasses", type: .glasses, color: Color(red: 0.6, green: 0.3, blue: 0.5)),
            Accessory(name: "Sunglasses", type: .sunglasses, color: .black),
            Accessory(name: "Aviators", type: .glasses, color: Color(red: 0.8, green: 0.7, blue: 0.3))
        ]
    }
    
    private var hatOptions: [Accessory] {
        [
            Accessory(name: "None", type: .hat, color: .clear),
            Accessory(name: "Baseball Cap", type: .hat, color: .blue),
            Accessory(name: "Beanie", type: .hat, color: .gray),
            Accessory(name: "Sun Hat", type: .hat, color: Color(red: 0.9, green: 0.8, blue: 0.6)),
            Accessory(name: "Fedora", type: .hat, color: .black),
            Accessory(name: "Beret", type: .hat, color: .red)
        ]
    }
    
    private var jewelryOptions: [Accessory] {
        [
            Accessory(name: "None", type: .necklace, color: .clear),
            Accessory(name: "Necklace", type: .necklace, color: Color(red: 0.8, green: 0.7, blue: 0.3)),
            Accessory(name: "Earrings", type: .earrings, color: Color(red: 0.8, green: 0.7, blue: 0.3)),
            Accessory(name: "Watch", type: .watch, color: .black),
            Accessory(name: "Bracelet", type: .bracelet, color: Color(red: 0.8, green: 0.7, blue: 0.3))
        ]
    }
    
    private var otherAccessories: [Accessory] {
        [
            Accessory(name: "Backpack", type: .backpack, color: .blue),
            Accessory(name: "Scarf", type: .other, color: .red),
            Accessory(name: "Tie", type: .other, color: .black),
            Accessory(name: "Bow Tie", type: .other, color: .red)
        ]
    }
}

struct AccessoryCategoryView: View {
    let title: String
    let icon: String
    let accessories: [Accessory]
    @Binding var selectedAccessories: [Accessory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(accessories, id: \.id) { accessory in
                    AccessoryCard(
                        accessory: accessory,
                        isSelected: isSelected(accessory)
                    ) {
                        toggleAccessory(accessory)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func isSelected(_ accessory: Accessory) -> Bool {
        if accessory.name == "None" {
            return !selectedAccessories.contains(where: { $0.type == accessory.type && $0.name != "None" })
        }
        return selectedAccessories.contains(where: { $0.id == accessory.id })
    }
    
    private func toggleAccessory(_ accessory: Accessory) {
        withAnimation(.spring(response: 0.3)) {
            if accessory.name == "None" {
                // Remove all accessories of this type
                selectedAccessories.removeAll(where: { $0.type == accessory.type })
            } else {
                // Remove existing accessories of same type, then add new one
                selectedAccessories.removeAll(where: { $0.type == accessory.type })
                selectedAccessories.append(accessory)
            }
        }
    }
}

struct AccessoryCard: View {
    let accessory: Accessory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? accessoryDisplayColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 80)
                    
                    VStack(spacing: 4) {
                        accessoryIcon
                            .font(.system(size: 32))
                            .foregroundStyle(isSelected ? accessoryDisplayColor : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Text(accessory.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var accessoryIcon: some View {
        switch accessory.type {
        case .glasses, .sunglasses:
            if accessory.name == "None" {
                Image(systemName: "xmark.circle")
            } else {
                Image(systemName: accessory.type == .sunglasses ? "sunglasses" : "eyeglasses")
            }
        case .hat:
            if accessory.name == "None" {
                Image(systemName: "xmark.circle")
            } else {
                Image(systemName: "person.fill.viewfinder")
            }
        case .earrings:
            Image(systemName: "circle.circle")
        case .necklace:
            if accessory.name == "None" {
                Image(systemName: "xmark.circle")
            } else {
                Image(systemName: "link.circle")
            }
        case .bracelet, .watch:
            Image(systemName: "watch")
        case .ring:
            Image(systemName: "diamond")
        case .backpack:
            Image(systemName: "backpack.fill")
        case .other:
            Image(systemName: "bag.fill")
        }
    }

    private var accessoryDisplayColor: Color {
        accessory.name == "None" ? .blue : accessory.color
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            let avatar = Avatar3DModel()
            
            ClothingSelectionView(avatar: avatar)
            AccessorySelectionView(avatar: avatar)
        }
        .padding()
    }
}
