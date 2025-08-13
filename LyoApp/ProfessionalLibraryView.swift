import SwiftUI

struct ProfessionalLibraryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Professional Library")
                    .font(.largeTitle)
                    .padding()
                
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    ProfessionalLibraryView()
}
