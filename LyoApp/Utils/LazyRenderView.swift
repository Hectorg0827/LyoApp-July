import SwiftUI

/// A view that delays the creation of its content until it is about to be displayed.
/// This is useful for improving performance in lists and tab views with complex content.
struct LazyRenderView<Content: View>: View {
    private let content: () -> Content
    
    init(_ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        _LazyView(content)
    }
}

/// A private helper view that defers the creation of its content.
private struct _LazyView<Content: View>: UIViewControllerRepresentable {
    private let content: () -> Content
    
    init(_ content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        return UIHostingController(rootView: content())
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        // The view is already created, so no update is needed.
        // The content inside the UIHostingController will manage its own updates.
    }
}
