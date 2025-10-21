import SwiftUI
import WebKit

// MARK: - Card Rail
// Horizontal/vertical scrolling rail of content cards (adaptive layout)

struct CardRail: View {
    let cards: [ContextualCard]
    let onCardTap: (ContentCard) -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedCardID: UUID?
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(DesignTokens.Colors.accent)
                
                Text("Resources")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(cards.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            // Card grid/scroll
            if isCompact {
                // iPhone: Vertical stacking
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cards) { contextualCard in
                            CardThumbnail(
                                card: contextualCard.card,
                                context: contextualCard.context,
                                reasonShown: contextualCard.reasonShown,
                                isSelected: selectedCardID == contextualCard.card.id
                            )
                            .onTapGesture {
                                selectedCardID = contextualCard.card.id
                                onCardTap(contextualCard.card)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // iPad: Horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(cards) { contextualCard in
                            CardThumbnail(
                                card: contextualCard.card,
                                context: contextualCard.context,
                                reasonShown: contextualCard.reasonShown,
                                isSelected: selectedCardID == contextualCard.card.id
                            )
                            .frame(width: 280)
                            .onTapGesture {
                                selectedCardID = contextualCard.card.id
                                onCardTap(contextualCard.card)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Card Thumbnail

struct CardThumbnail: View {
    let card: ContentCard
    let context: CardContext
    let reasonShown: String
    let isSelected: Bool
    
    @State private var isPinged = false
    
    private var thumbnailView: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnailURL = card.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderRectangle(opacity: 0.3, showProgress: true)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderRectangle(opacity: 1.0, showProgress: false)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderRectangle(opacity: 1.0, showProgress: false)
            }
            
            typeBadge
        }
        .frame(height: 140)
        .clipped()
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }
    
    private func placeholderRectangle(opacity: Double, showProgress: Bool) -> some View {
        Rectangle()
            .fill(card.kind.color.opacity(opacity))
            .overlay {
                if showProgress {
                    ProgressView()
                } else {
                    Image(systemName: card.kind.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
    }
    
    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: card.kind.iconName)
                .font(.system(size: 10))
            Text(card.kind.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(card.kind.color)
        .cornerRadius(6)
        .padding(8)
    }
    
    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            contextTag
            titleText
            sourceAndDuration
            reasonText
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
    }
    
    private var contextTag: some View {
        HStack(spacing: 4) {
            Text(context.emoji)
                .font(.system(size: 12))
            Text(context.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var titleText: some View {
        Text(card.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var sourceAndDuration: some View {
        HStack {
            Text(card.source)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text("\(card.estMinutes) min")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var reasonText: some View {
        Text(reasonShown)
            .font(.system(size: 11))
            .foregroundColor(DesignTokens.Colors.accent)
            .italic()
            .lineLimit(1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailView
            cardInfoSection
        }
        .background(Color.white.opacity(isSelected ? 0.15 : 0.08))
        .cornerRadius(12)
        .border(isSelected ? DesignTokens.Colors.accent : Color.clear, width: 2)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(isPinged ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPinged)
        .onAppear {
            // Removed: card.isPinged property doesn't exist in ContentCard model
            if false { // Placeholder - could track ping state elsewhere
                // Animate "New card!" ping
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPinged = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isPinged = false
                    }
                }
            }
        }
    }
}

// MARK: - Content Card Viewer
// Full-screen viewer for cards (WebView, video player, etc.)

struct ContentCardViewer: View {
    let card: ContentCard
    let onSaveNote: (SessionNote) -> Void
    let onDismiss: () -> Void
    
    @State private var noteText: String = ""
    @State private var showingNoteSaved: Bool = false
    @StateObject private var courseStore = CourseStore.shared
    
    var body: some View {
        ZStack {
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Type badge
                    HStack(spacing: 6) {
                        Image(systemName: card.kind.iconName)
                        Text(card.kind.rawValue)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(card.kind.color)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text(card.source)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                    Text("\(card.estMinutes) min")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Web content
                        WebView(url: card.url)
                            .frame(height: 500)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        
                        // Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(card.summary)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Citation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Citation")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(card.citation)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Notes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            TextEditor(text: $noteText)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(12)
                                .frame(minHeight: 100)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                            
                            Button(action: saveNote) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text(showingNoteSaved ? "Saved!" : "Save Note with Citation")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    showingNoteSaved
                                        ? DesignTokens.Colors.success
                                        : DesignTokens.Colors.accent
                                )
                                .cornerRadius(12)
                            }
                            .disabled(noteText.isEmpty || showingNoteSaved)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            
            // Success overlay
            if showingNoteSaved {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Note saved with citation!")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(DesignTokens.Colors.success)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showingNoteSaved)
            }
        }
    }
    
    private func saveNote() {
        guard !noteText.isEmpty else { return }
        
        let note = SessionNote(
            content: noteText,
            cardID: card.id,
            timestamp: Date(),
            tags: card.tags,
            citation: card.citation
        )
        
        onSaveNote(note)
        courseStore.saveNote(note)
        
        // Update user signals
        var signals = courseStore.userSignals
        signals.recordCardOpen(card)
        courseStore.updateUserSignals(signals)
        
        withAnimation {
            showingNoteSaved = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingNoteSaved = false
                noteText = ""
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - WebView (UIViewRepresentable)

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
