import SwiftUI

struct MessengerView: View {
    @StateObject private var viewModel = MessengerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(viewModel.messages) { msg in
                            HStack {
                                if msg.isFromUser { Spacer() }
                                Text(msg.content)
                                    .padding()
                                    .background(msg.isFromUser ? DesignTokens.Colors.neonBlue : DesignTokens.Colors.glassBg)
                                    .foregroundColor(msg.isFromUser ? .white : DesignTokens.Colors.primary)
                                    .cornerRadius(DesignTokens.Radius.md)
                                if !msg.isFromUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                        if viewModel.isTyping {
                            HStack {
                                Spacer()
                                TypingIndicator()
                                Spacer()
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            Divider()
            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Message...", text: $viewModel.currentInput)
                    .padding(DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.glassBg)
                    .cornerRadius(DesignTokens.Radius.md)
                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.currentInput.isEmpty ? DesignTokens.Colors.gray400 : DesignTokens.Colors.neonBlue)
                }
                .disabled(viewModel.currentInput.isEmpty)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.background)
        }
        .background(DesignTokens.Colors.primaryBg)
    }
}

class MessengerViewModel: ObservableObject {
    @Published var messages: [MessengerMessage] = [
        MessengerMessage(id: UUID(), content: "Welcome to Messenger!", isFromUser: false)
    ]
    @Published var currentInput: String = ""
    @Published var isTyping: Bool = false

    func sendMessage() {
        let text = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let msg = MessengerMessage(id: UUID(), content: text, isFromUser: true)
        messages.append(msg)
        currentInput = ""
        isTyping = true
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.messages.append(MessengerMessage(id: UUID(), content: "AI: Got your message!", isFromUser: false))
            self.isTyping = false
        }
    }
}

struct MessengerMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
}
