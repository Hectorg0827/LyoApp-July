import SwiftUI

struct MouthCustomizationPanel: View {
    @Binding var mouthShape: String
    @Binding var lipColor: String

    let mouthShapes = ["Full", "Thin", "Heart", "Wide", "Small"]
    let lipColors = ["Natural", "Pink", "Red", "Nude", "Berry"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mouth Customization")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                Text("Mouth Shape")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(mouthShapes, id: \.self) { shape in
                        Button(action: { mouthShape = shape }) {
                            Text(shape)
                                .font(.system(size: 14))
                                .foregroundColor(mouthShape == shape ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(mouthShape == shape ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Lip Color")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(lipColors, id: \.self) { color in
                        ColorButton(
                            color: color,
                            isSelected: lipColor == color
                        ) {
                            lipColor = color
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}