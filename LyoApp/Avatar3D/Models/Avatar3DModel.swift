//
//  Avatar3DModel.swift
//  LyoApp
//
//  Comprehensive 3D Avatar Model with full customization
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Avatar Species

enum AvatarSpecies: String, Codable, CaseIterable {
    case human = "Human"
    case animal = "Animal"
    case robot = "Robot"
    
    var icon: String {
        switch self {
        case .human: return "person.fill"
        case .animal: return "pawprint.fill"
        case .robot: return "cpu.fill"
        }
    }
    
    var description: String {
        switch self {
        case .human: return "Create a human avatar"
        case .animal: return "Become your favorite animal"
        case .robot: return "Build a cool robot"
        }
    }
    
    var baseModelName: String {
        switch self {
        case .human: return "human_base"
        case .animal: return "animal_base"
        case .robot: return "robot_base"
        }
    }
}

// MARK: - Gender Options

enum AvatarGender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case neutral = "Neutral"
    
    var icon: String {
        switch self {
        case .male: return "person"
        case .female: return "person.fill"
        case .neutral: return "person.2"
        }
    }
}

extension AvatarGender {
    var description: String { rawValue }
}

// MARK: - Facial Features

enum FaceShape: String, Codable, CaseIterable {
    case oval = "Oval"
    case round = "Round"
    case square = "Square"
    case heart = "Heart"
    case diamond = "Diamond"
    case long = "Long"
    
    var previewIcon: String {
        return "circle.fill"
    }
}

enum EyeShape: String, Codable, CaseIterable {
    case round = "Round"
    case almond = "Almond"
    case hooded = "Hooded"
    case upturned = "Upturned"
    case downturned = "Downturned"
    case monolid = "Monolid"
    
    var previewIcon: String {
        return "eye.fill"
    }
}

enum EyeColor: String, Codable, CaseIterable {
    case brown = "Brown"
    case blue = "Blue"
    case green = "Green"
    case hazel = "Hazel"
    case amber = "Amber"
    case gray = "Gray"
    case custom = "Custom"
    
    var color: Color {
        switch self {
        case .brown: return Color(hex: "#5C4033")
        case .blue: return Color(hex: "#4A90E2")
        case .green: return Color(hex: "#7CB342")
        case .hazel: return Color(hex: "#8E7F3F")
        case .amber: return Color(hex: "#FF7F00")
        case .gray: return Color(hex: "#6E7F80")
        case .custom: return .blue
        }
    }
}

enum NoseType: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case button = "Button"
    case roman = "Roman"
    case snub = "Snub"
}

enum MouthShape: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case full = "Full"
    case wide = "Wide"
    case cupid = "Cupid's Bow"
    case thin = "Thin"
}

struct FacialFeatures: Equatable {
    var faceShape: FaceShape
    var eyeShape: EyeShape
    var eyeColor: EyeColor
    var customEyeColor: String?
    var eyeLashes: Bool
    var eyebrowStyle: String
    var noseType: NoseType
    var mouthShape: MouthShape
    var earSize: Double // 0.0 - 1.0
    var freckles: Bool
    
    // Additional properties for fine-tuning
    var eyeSize: Double = 1.0 // Scale factor for eye size
    var eyeSpacing: Double = 1.0 // Scale factor for spacing between eyes
    var noseSize: Double = 1.0 // Scale factor for nose size
    var lipColor: Color = Color(red: 0.8, green: 0.3, blue: 0.3) // Lip color
    var hasEyelashes: Bool = true // Whether to render eyelashes
    var cheekboneProminence: Double = 1.0
    
    // Color stored as hex string for Codable
    private var lipColorHex: String {
        get { lipColor.toHex() ?? "#CC4D4D" }
        set { lipColor = Color(hex: newValue) }
    }
    
    static let `default` = FacialFeatures(
        faceShape: .oval,
        eyeShape: .almond,
        eyeColor: .brown,
        customEyeColor: nil,
        eyeLashes: true,
        eyebrowStyle: "Natural",
        noseType: .medium,
        mouthShape: .medium,
        earSize: 0.5,
        freckles: false,
        eyeSize: 1.0,
        eyeSpacing: 1.0,
        noseSize: 1.0,
        lipColor: Color(red: 0.8, green: 0.3, blue: 0.3),
        hasEyelashes: true,
        cheekboneProminence: 1.0
    )
}

extension FacialFeatures: Codable {
    enum CodingKeys: String, CodingKey {
        case faceShape, eyeShape, eyeColor, customEyeColor, eyeLashes
        case eyebrowStyle, noseType, mouthShape, earSize, freckles
        case eyeSize, eyeSpacing, noseSize, lipColorHex, hasEyelashes, cheekboneProminence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        faceShape = try container.decode(FaceShape.self, forKey: .faceShape)
        eyeShape = try container.decode(EyeShape.self, forKey: .eyeShape)
        eyeColor = try container.decode(EyeColor.self, forKey: .eyeColor)
        customEyeColor = try container.decodeIfPresent(String.self, forKey: .customEyeColor)
        eyeLashes = try container.decode(Bool.self, forKey: .eyeLashes)
        eyebrowStyle = try container.decode(String.self, forKey: .eyebrowStyle)
        noseType = try container.decode(NoseType.self, forKey: .noseType)
        mouthShape = try container.decode(MouthShape.self, forKey: .mouthShape)
        earSize = try container.decodeIfPresent(Double.self, forKey: .earSize) ?? 0.5
        freckles = try container.decode(Bool.self, forKey: .freckles)
        eyeSize = try container.decodeIfPresent(Double.self, forKey: .eyeSize) ?? 1.0
        eyeSpacing = try container.decodeIfPresent(Double.self, forKey: .eyeSpacing) ?? 1.0
        noseSize = try container.decodeIfPresent(Double.self, forKey: .noseSize) ?? 1.0
        let hexColor = try container.decodeIfPresent(String.self, forKey: .lipColorHex) ?? "#CC4D4D"
        lipColor = Color(hex: hexColor)
        hasEyelashes = try container.decodeIfPresent(Bool.self, forKey: .hasEyelashes) ?? true
        cheekboneProminence = try container.decodeIfPresent(Double.self, forKey: .cheekboneProminence) ?? 1.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(faceShape, forKey: .faceShape)
        try container.encode(eyeShape, forKey: .eyeShape)
        try container.encode(eyeColor, forKey: .eyeColor)
        try container.encodeIfPresent(customEyeColor, forKey: .customEyeColor)
        try container.encode(eyeLashes, forKey: .eyeLashes)
        try container.encode(eyebrowStyle, forKey: .eyebrowStyle)
        try container.encode(noseType, forKey: .noseType)
        try container.encode(mouthShape, forKey: .mouthShape)
        try container.encode(earSize, forKey: .earSize)
        try container.encode(freckles, forKey: .freckles)
        try container.encode(eyeSize, forKey: .eyeSize)
        try container.encode(eyeSpacing, forKey: .eyeSpacing)
        try container.encode(noseSize, forKey: .noseSize)
        try container.encode(lipColorHex, forKey: .lipColorHex)
        try container.encode(hasEyelashes, forKey: .hasEyelashes)
        try container.encode(cheekboneProminence, forKey: .cheekboneProminence)
    }
}

// MARK: - Hair Configuration

enum HairStyle: String, Codable, CaseIterable {
    // Generic categories
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    
    // Short styles
    case pixie = "Pixie Cut"
    case buzz = "Buzz Cut"
    case crew = "Crew Cut"
    case undercut = "Undercut"
    case bob = "Bob"
    case shortCurly = "Short Curly"
    
    // Medium styles
    case shoulder = "Shoulder Length"
    case lob = "Long Bob"
    case shag = "Shag"
    case wavy = "Wavy"
    case layers = "Layered"
    
    // Long styles
    case straight = "Long Straight"
    case curly = "Long Curly"
    case braids = "Braids"
    case ponytail = "Ponytail"
    case bun = "Bun"
    case dreadlocks = "Dreadlocks"
    
    // Special
    case afro = "Afro"
    case mohawk = "Mohawk"
    case bald = "Bald"
    
    var category: String {
        if [.pixie, .buzz, .crew, .undercut, .bob, .shortCurly].contains(self) {
            return "Short"
        } else if [.shoulder, .lob, .shag, .wavy, .layers].contains(self) {
            return "Medium"
        } else if [.straight, .curly, .braids, .ponytail, .bun, .dreadlocks].contains(self) {
            return "Long"
        } else {
            return "Special"
        }
    }
}

enum HairColor: String, Codable, CaseIterable {
    case black = "Black"
    case brown = "Brown"
    case blonde = "Blonde"
    case red = "Red"
    case auburn = "Auburn"
    case gray = "Gray"
    case white = "White"
    case pink = "Pink"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"
    case custom = "Custom"
    
    var color: Color {
        switch self {
        case .black: return Color(hex: "#1C1C1C")
        case .brown: return Color(hex: "#5C4033")
        case .blonde: return Color(hex: "#F5E6D3")
        case .red: return Color(hex: "#8B2500")
        case .auburn: return Color(hex: "#A52A2A")
        case .gray: return Color(hex: "#808080")
        case .white: return Color(hex: "#F5F5F5")
        case .pink: return Color(hex: "#FF69B4")
        case .blue: return Color(hex: "#4169E1")
        case .green: return Color(hex: "#32CD32")
        case .purple: return Color(hex: "#9370DB")
        case .custom: return .blue
        }
    }
}

enum FacialHairStyle: String, Codable, CaseIterable {
    case none = "Clean Shaven"
    case stubble = "Stubble"
    case beard = "Beard" // Generic beard option
    case goatee = "Goatee"
    case vandyke = "Van Dyke"
    case mustache = "Mustache"
    case fullBeard = "Full Beard"
    case soulPatch = "Soul Patch"
    case chinstrap = "Chinstrap"
}

struct HairConfiguration: Codable, Equatable {
    var style: HairStyle
    var color: HairColor
    var customColor: String?
    var facialHair: FacialHairStyle
    var facialHairColor: HairColor?
    var length: Float // 0.0 - 1.0 for adjustable styles
    var hasHighlights: Bool // NEW: Support for hair highlights
    var highlightColor: HairColor? // NEW: Highlight color
    
    static let `default` = HairConfiguration(
        style: .shoulder,
        color: .brown,
        customColor: nil,
        facialHair: .none,
        facialHairColor: nil,
        length: 0.5,
        hasHighlights: false,
        highlightColor: nil
    )
}

// MARK: - Clothing & Accessories

enum ClothingStyle: String, Codable, CaseIterable {
    case casual = "Casual"
    case formal = "Formal"
    case sporty = "Sporty"
    case elegant = "Elegant"
    case streetwear = "Streetwear"
    case professional = "Professional"
    case creative = "Creative"
}

struct ClothingItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: ClothingType
    var style: String
    var color: Color
    var pattern: String?
    
    enum ClothingType: String, Codable {
        case top = "Top"
        case bottom = "Bottom"
        case outerwear = "Outerwear"
        case footwear = "Footwear"
        case shirt = "Shirt"
        case pants = "Pants"
        case dress = "Dress"
        case jacket = "Jacket"
        case shoes = "Shoes"
        case hat = "Hat"
        case scarf = "Scarf"
    }
    
    init(id: UUID = UUID(), name: String, type: ClothingType, style: String = "", color: Color, pattern: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.style = style
        self.color = color
        self.pattern = pattern
    }
}

extension ClothingItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, style, colorHex, pattern
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ClothingType.self, forKey: .type)
        style = try container.decode(String.self, forKey: .style)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex)
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(style, forKey: .style)
        try container.encode(color.toHex() ?? "#000000", forKey: .colorHex)
        try container.encodeIfPresent(pattern, forKey: .pattern)
    }
}

struct ClothingSet: Codable, Equatable {
    var style: ClothingStyle
    var top: ClothingItem?
    var bottom: ClothingItem?
    var shoes: ClothingItem?
    var outerwear: ClothingItem?
    
    static let casual = ClothingSet(
        style: .casual,
        top: ClothingItem(name: "T-Shirt", type: .shirt, style: "T-Shirt", color: Color(hex: "#4A90E2")),
        bottom: ClothingItem(name: "Jeans", type: .pants, style: "Jeans", color: Color(hex: "#2C3E50")),
        shoes: ClothingItem(name: "Sneakers", type: .shoes, style: "Sneakers", color: Color(hex: "#FFFFFF")),
        outerwear: nil
    )
    
    static let formal = ClothingSet(
        style: .formal,
        top: ClothingItem(name: "Button-Up", type: .shirt, style: "Button-Up", color: Color(hex: "#FFFFFF")),
        bottom: ClothingItem(name: "Dress Pants", type: .pants, style: "Dress Pants", color: Color(hex: "#1C1C1C")),
        shoes: ClothingItem(name: "Oxford Shoes", type: .shoes, style: "Oxford", color: Color(hex: "#8B4513")),
        outerwear: nil
    )
}

struct Accessory: Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: AccessoryType
    var style: String
    var color: Color
    
    enum AccessoryType: String, Codable, CaseIterable {
        case glasses = "Glasses"
        case sunglasses = "Sunglasses"
        case earrings = "Earrings"
        case necklace = "Necklace"
        case bracelet = "Bracelet"
        case watch = "Watch"
        case ring = "Ring"
        case backpack = "Backpack"
        case hat = "Hat"
        case other = "Other"
    }
    
    init(id: UUID = UUID(), name: String, type: AccessoryType, style: String = "", color: Color) {
        self.id = id
        self.name = name
        self.type = type
        self.style = style
        self.color = color
    }
}

extension Accessory: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, style, colorHex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(AccessoryType.self, forKey: .type)
        style = try container.decode(String.self, forKey: .style)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(style, forKey: .style)
        try container.encode(color.toHex() ?? "#000000", forKey: .colorHex)
    }
}

// MARK: - Skin Tone

enum SkinTone: String, Codable, CaseIterable {
    case pale = "Pale"
    case fair = "Fair"
    case light = "Light"
    case medium = "Medium"
    case olive = "Olive"
    case tan = "Tan"
    case brown = "Brown"
    case dark = "Dark"
    case ebony = "Ebony"
    case custom = "Custom"
    
    var color: Color {
        switch self {
        case .pale: return Color(hex: "#F5E6D3")
        case .fair: return Color(hex: "#F0D5B8")
        case .light: return Color(hex: "#E8C4A1")
        case .medium: return Color(hex: "#D4A574")
        case .olive: return Color(hex: "#C19A6B")
        case .tan: return Color(hex: "#B08B5B")
        case .brown: return Color(hex: "#8D5524")
        case .dark: return Color(hex: "#704214")
        case .ebony: return Color(hex: "#4A2511")
        case .custom: return .orange
        }
    }
}

// MARK: - Main Avatar 3D Model

class Avatar3DModel: ObservableObject, Codable {
    // Basic Info
    @Published var name: String
    @Published var species: AvatarSpecies
    @Published var gender: AvatarGender
    
    // Physical Appearance
    @Published var skinTone: SkinTone
    @Published var customSkinColor: String?
    @Published var facialFeatures: FacialFeatures
    @Published var hair: HairConfiguration
    
    // Style
    @Published var clothing: ClothingSet
    @Published var accessories: [Accessory]
    
    // Voice & Animation
    @Published var voiceId: String
    @Published var voicePitch: Float
    @Published var voiceSpeed: Float // Voice playback speed
    @Published var defaultExpression: String
    
    // Metadata
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(
        name: String = "My Avatar",
        species: AvatarSpecies = .human,
        gender: AvatarGender = .neutral,
        skinTone: SkinTone = .medium,
        customSkinColor: String? = nil,
        facialFeatures: FacialFeatures = .default,
        hair: HairConfiguration = .default,
        clothing: ClothingSet = .casual,
        accessories: [Accessory] = [],
        voiceId: String = "default",
        voicePitch: Float = 1.0,
        voiceSpeed: Float = 1.0,
        defaultExpression: String = "neutral",
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.species = species
        self.gender = gender
        self.skinTone = skinTone
        self.customSkinColor = customSkinColor
        self.facialFeatures = facialFeatures
        self.hair = hair
        self.clothing = clothing
        self.accessories = accessories
        self.voiceId = voiceId
        self.voicePitch = voicePitch
        self.voiceSpeed = voiceSpeed
        self.defaultExpression = defaultExpression
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case name, species, gender, skinTone, customSkinColor
        case facialFeatures, hair, clothing, accessories
        case voiceId, voicePitch, voiceSpeed, defaultExpression
        case id, createdAt, updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        species = try container.decode(AvatarSpecies.self, forKey: .species)
        gender = try container.decode(AvatarGender.self, forKey: .gender)
        skinTone = try container.decode(SkinTone.self, forKey: .skinTone)
        customSkinColor = try container.decodeIfPresent(String.self, forKey: .customSkinColor)
        facialFeatures = try container.decode(FacialFeatures.self, forKey: .facialFeatures)
        hair = try container.decode(HairConfiguration.self, forKey: .hair)
        clothing = try container.decode(ClothingSet.self, forKey: .clothing)
        accessories = try container.decode([Accessory].self, forKey: .accessories)
        voiceId = try container.decode(String.self, forKey: .voiceId)
        voicePitch = try container.decode(Float.self, forKey: .voicePitch)
        voiceSpeed = try container.decode(Float.self, forKey: .voiceSpeed)
        defaultExpression = try container.decode(String.self, forKey: .defaultExpression)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(species, forKey: .species)
        try container.encode(gender, forKey: .gender)
        try container.encode(skinTone, forKey: .skinTone)
        try container.encodeIfPresent(customSkinColor, forKey: .customSkinColor)
        try container.encode(facialFeatures, forKey: .facialFeatures)
        try container.encode(hair, forKey: .hair)
        try container.encode(clothing, forKey: .clothing)
        try container.encode(accessories, forKey: .accessories)
        try container.encode(voiceId, forKey: .voiceId)
        try container.encode(voicePitch, forKey: .voicePitch)
        try container.encode(voiceSpeed, forKey: .voiceSpeed)
        try container.encode(defaultExpression, forKey: .defaultExpression)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    func updateTimestamp() {
        updatedAt = Date()
    }
    
    func duplicate() -> Avatar3DModel {
        return Avatar3DModel(
            name: "\(name) Copy",
            species: species,
            gender: gender,
            skinTone: skinTone,
            customSkinColor: customSkinColor,
            facialFeatures: facialFeatures,
            hair: hair,
            clothing: clothing,
            accessories: accessories,
            voiceId: voiceId,
            voicePitch: voicePitch,
            defaultExpression: defaultExpression
        )
    }
}

// MARK: - Color Extension for Avatar3D

extension Color {
    func toHex() -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        #else
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        #endif
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }

    var hexString: String {
        toHex() ?? "#000000"
    }
}

extension FacialFeatures {
    var resolvedEyeColor: Color {
        if eyeColor == .custom, let hex = customEyeColor {
            return Color(hex: hex)
        }
        return eyeColor.color
    }
    
    mutating func applyEyeColor(_ color: Color) {
        let hex = color.toHex() ?? EyeColor.blue.color.toHex() ?? "#4A90E2"
        if let match = EyeColor.allCases.first(where: { $0 != .custom && $0.color.toHex() == hex }) {
            eyeColor = match
            customEyeColor = nil
        } else {
            eyeColor = .custom
            customEyeColor = hex
        }
    }
}

extension HairConfiguration {
    var resolvedBaseColor: Color {
        if color == .custom, let customColor {
            return Color(hex: customColor)
        }
        return color.color
    }
    
    var resolvedHighlightColor: Color? {
        guard let highlightColor else { return nil }
        if highlightColor == .custom, let customColor {
            return Color(hex: customColor)
        }
        return highlightColor.color
    }
}
