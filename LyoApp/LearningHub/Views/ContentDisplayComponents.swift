import SwiftUI

// Temporary clean placeholder to remove previous malformed top-level statements.
public struct ContentDisplayComponents_Placeholder: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Badge: View {
    let text: String
    let color: Color
    public init(text: String, color: Color) { self.text = text; self.color = color }
    public var body: some View {
        Text(text.uppercased())
            .font(.caption2).fontWeight(.bold)
            .foregroundColor(.white)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 4).fill(color))
    }
}

public struct DifficultyIndicator: View {
    let level: String
    public init(level: String) { self.level = level }
    public var body: some View {
        HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { idx in
                Circle()
                    .fill(idx < numericValue ? levelColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    private var numericValue: Int { switch level.lowercased() { case "beginner": return 1; case "intermediate": return 2; case "advanced": return 3; default: return 1 } }
    private var levelColor: Color { switch numericValue { case 1: return .green; case 2: return .orange; case 3: return .red; default: return .green } }
}
