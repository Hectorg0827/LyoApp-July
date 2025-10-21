import SwiftUI

struct FaceShapeSelector: View {
    @Binding var selectedShape: String
    @State private var isExpanded = false

    let faceShapes = [
        "Oval", "Round", "Square", "Heart", "Diamond"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Face Shape")
                .font(.headline)
                .foregroundColor(.white)

            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(selectedShape.isEmpty ? "Select Face Shape" : selectedShape)
                        .foregroundColor(selectedShape.isEmpty ? .gray : .white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(faceShapes, id: \.self) { shape in
                        Button(action: {
                            selectedShape = shape
                            isExpanded = false
                        }) {
                            HStack {
                                Text(shape)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedShape == shape {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(selectedShape == shape ? Color.blue.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
    }
}