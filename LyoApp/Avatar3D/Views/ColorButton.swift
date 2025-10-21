import SwiftUI

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    private var colorValue: Color {
        switch color.lowercased() {
        case "brown": return Color(hex: "8B4513")
        case "blue": return Color(hex: "4169E1")
        case "green": return Color(hex: "228B22")
        case "hazel": return Color(hex: "D2691E")
        case "gray": return Color(hex: "708090")
        case "natural": return Color(hex: "FFB6C1")
        case "pink": return Color(hex: "FF69B4")
        case "red": return Color(hex: "DC143C")
        case "nude": return Color(hex: "F5DEB3")
        case "berry": return Color(hex: "8A2BE2")
        default: return Color.gray
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(colorValue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? Color.white.opacity(0.5) : Color.clear, radius: 4)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}