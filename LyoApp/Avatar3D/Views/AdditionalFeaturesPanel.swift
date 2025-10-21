import SwiftUI

struct AdditionalFeaturesPanel: View {
    @Binding var freckles: Bool
    @Binding var dimples: Bool
    @Binding var beautyMark: Bool
    @Binding var glasses: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Features")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ToggleRow(title: "Freckles", isOn: $freckles)
                ToggleRow(title: "Dimples", isOn: $dimples)
                ToggleRow(title: "Beauty Mark", isOn: $beautyMark)
                ToggleRow(title: "Glasses", isOn: $glasses)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(.vertical, 4)
    }
}