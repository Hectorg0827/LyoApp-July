import SwiftUI

struct NoseCustomizationPanel: View {
    @Binding var noseShape: String
    @Binding var noseSize: Double

    let noseShapes = ["Button", "Straight", "Roman", "Upturned", "Bulbous"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nose Customization")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                Text("Nose Shape")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(noseShapes, id: \.self) { shape in
                        Button(action: { noseShape = shape }) {
                            Text(shape)
                                .font(.system(size: 14))
                                .foregroundColor(noseShape == shape ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(noseShape == shape ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nose Size")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.1f", noseSize))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Slider(value: $noseSize, in: 0.5...2.0, step: 0.1)
                    .accentColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}