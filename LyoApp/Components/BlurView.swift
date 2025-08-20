import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
    
    // Convenience initializer for common blur effects
    static let systemMaterialDark = BlurView(style: .systemMaterialDark)
    static let systemMaterialLight = BlurView(style: .systemMaterialLight)
    static let systemMaterial = BlurView(style: .systemMaterial)
    static let systemThinMaterialDark = BlurView(style: .systemThinMaterialDark)
    static let systemThinMaterialLight = BlurView(style: .systemThinMaterialLight)
    static let systemThinMaterial = BlurView(style: .systemThinMaterial)
}
