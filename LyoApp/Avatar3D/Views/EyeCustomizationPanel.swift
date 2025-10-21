import SwiftUI

struct EyeCustomizationPanel: View {
    @Binding var eyeColor: String
    @Binding var eyeShape: String

    let eyeColors = ["Brown", "Blue", "Green", "Hazel", "Gray"]
    let eyeShapes = ["Almond", "Round", "Hooded", "Wide", "Narrow"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Eye Customization")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                Text("Eye Color")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(eyeColors, id: \.self) { color in
                        ColorButton(
                            color: color,
                            isSelected: eyeColor == color
                        ) {
                            eyeColor = color
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Eye Shape")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(eyeShapes, id: \.self) { shape in
                        Button(action: { eyeShape = shape }) {
                            Text(shape)
                                .font(.system(size: 14))
                                .foregroundColor(eyeShape == shape ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(eyeShape == shape ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                .cornerRadius(20)
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