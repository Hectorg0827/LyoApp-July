import SwiftUI

struct MessageBubble: View {
    let message: AIMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isFromUser {
                // Suddy Buddy avatar
                Image("suddy_buddy_avatar")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(DesignTokens.Colors.neonBlue, lineWidth: 2))
                    .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.4), radius: 6)
            }
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(message.isFromUser ? .white : DesignTokens.Colors.primary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(message.isFromUser ? DesignTokens.Colors.neonBlue.opacity(0.7) : DesignTokens.Colors.glassBg.opacity(0.8))
                            .shadow(color: message.isFromUser ? DesignTokens.Colors.neonBlue.opacity(0.2) : .clear, radius: 4)
                    )
            }
            if message.isFromUser {
                Spacer(minLength: 36)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
}
