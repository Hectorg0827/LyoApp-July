
import SwiftUI
import Foundation

/// Main dispatcher view that renders the appropriate component based on block type
struct LessonBlockView: View {
    let block: LessonBlock

    var body: some View {
        switch block.data {
        case .heading(let data):
            HeadingView(data: data)
        case .paragraph(let data):
            ParagraphView(data: data)
        case .bulletList(let data):
            BulletListView(data: data)
        case .numberedList(let data):
            NumberedListView(data: data)
        case .image(let data):
            ImageView(data: data)
        case .video(let data):
            VideoView(data: data)
        case .codeBlock(let data):
            CodeBlockView(data: data)
        case .quote(let data):
            QuoteView(data: data)
        case .callout(let data):
            CalloutView(data: data)
        case .divider(let data):
            DividerView(data: data)
        case .youtube(let data):
            YouTubePlayerView(data: data)
        case .interactiveElement(let data):
            InteractiveElementView(data: data)
        case .quiz(let data):
            QuizView(data: data)
        case .diagram(let data):
            DiagramView(data: data)
        case .table(let data):
            TableView(data: data)
        case .spacer(let data):
            SpacerView(data: data)
        }
    }
}

// MARK: - Individual Component Views

struct HeadingView: View {
    let data: HeadingData
    
    var body: some View {
        Text(data.text)
            .font(fontForLevel(data.level))
            .foregroundColor(colorForStyle(data.style))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, spacingForLevel(data.level))
            .accessibilityAddTraits(.isHeader)
    }
    
    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return DesignTokens.Typography.title1
        case 2: return DesignTokens.Typography.title2
        case 3: return DesignTokens.Typography.title3
        case 4: return DesignTokens.Typography.headline
        case 5: return DesignTokens.Typography.subheadline
        case 6: return DesignTokens.Typography.body
        default: return DesignTokens.Typography.body
        }
    }
    
    private func colorForStyle(_ style: HeadingData.HeadingStyle?) -> Color {
        switch style {
        case .emphasized: return DesignTokens.Colors.primary
        case .subtitle: return DesignTokens.Colors.textSecondary
        case .normal, .none: return DesignTokens.Colors.textPrimary
        }
    }
    
    private func spacingForLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1: return DesignTokens.Spacing.lg
        case 2: return DesignTokens.Spacing.md
        case 3: return DesignTokens.Spacing.sm
        default: return DesignTokens.Spacing.xs
        }
    }
}

struct ParagraphView: View {
    let data: ParagraphData
    
    var body: some View {
        Text(data.text)
            .font(DesignTokens.Typography.body)
            .foregroundColor(colorForStyle(data.style))
            .multilineTextAlignment(alignmentForStyle(data.style))
            .frame(maxWidth: .infinity, alignment: frameAlignmentForStyle(data.style))
            .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    private func colorForStyle(_ style: ParagraphData.ParagraphStyle?) -> Color {
        switch style {
        case .emphasized: return DesignTokens.Colors.primary
        case .muted: return DesignTokens.Colors.textSecondary
        case .normal, .centered, .none: return DesignTokens.Colors.textPrimary
        }
    }
    
    private func alignmentForStyle(_ style: ParagraphData.ParagraphStyle?) -> TextAlignment {
        switch style {
        case .centered: return .center
        default: return .leading
        }
    }
    
    private func frameAlignmentForStyle(_ style: ParagraphData.ParagraphStyle?) -> Alignment {
        switch style {
        case .centered: return .center
        default: return .leading
        }
    }
}

struct BulletListView: View {
    let data: BulletListData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            ForEach(data.items.indices, id: \.self) { index in
                BulletListItemView(
                    item: data.items[index],
                    style: data.style ?? .bullet,
                    level: 0
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct BulletListItemView: View {
    let item: ListItem
    let style: BulletListData.ListStyle
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Text(bulletSymbol)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(width: 16, alignment: .leading)
                
                Text(item.text)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(level * 20))
            
            // Render sub-items if they exist
            if let subItems = item.subItems {
                ForEach(subItems.indices, id: \.self) { index in
                    BulletListItemView(
                        item: subItems[index],
                        style: style,
                        level: level + 1
                    )
                }
            }
        }
    }
    
    private var bulletSymbol: String {
        switch style {
        case .bullet: return "•"
        case .dash: return "−"
        case .checkmark: return "✓"
        }
    }
}

struct NumberedListView: View {
    let data: NumberedListData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            ForEach(data.items.indices, id: \.self) { index in
                NumberedListItemView(
                    item: data.items[index],
                    number: (data.startNumber ?? 1) + index,
                    style: data.style ?? .decimal,
                    level: 0
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct NumberedListItemView: View {
    let item: ListItem
    let number: Int
    let style: NumberedListData.NumberedListStyle
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Text(numberString)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(width: 24, alignment: .leading)
                
                Text(item.text)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(level * 20))
            
            // Render sub-items if they exist
            if let subItems = item.subItems {
                ForEach(subItems.indices, id: \.self) { index in
                    NumberedListItemView(
                        item: subItems[index],
                        number: index + 1,
                        style: style,
                        level: level + 1
                    )
                }
            }
        }
    }
    
    private var numberString: String {
        switch style {
        case .decimal: return "\(number)."
        case .roman: return "\(romanNumeral(number))."
        case .letter: return "\(letterFromNumber(number))."
        }
    }
    
    private func romanNumeral(_ number: Int) -> String {
        let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        var result = ""
        var num = number
        
        for (index, value) in values.enumerated() {
            while num >= value {
                result += numerals[index]
                num -= value
            }
        }
        
        return result.lowercased()
    }
    
    private func letterFromNumber(_ number: Int) -> String {
        let letter = Character(UnicodeScalar(96 + number)!)
        return String(letter)
    }
}

struct ImageView: View {
    let data: ImageData
    
    var body: some View {
        VStack(alignment: alignmentForImage(data.alignment), spacing: DesignTokens.Spacing.sm) {
            AsyncImage(url: URL(string: data.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: data.width, maxHeight: data.height)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            } placeholder: {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(maxWidth: data.width ?? 300, maxHeight: data.height ?? 200)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                    )
            }
            .accessibilityLabel(data.altText)
            
            if let caption = data.caption {
                Text(caption)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignmentForImage(data.alignment))
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    private func alignmentForImage(_ alignment: ImageData.ImageAlignment?) -> HorizontalAlignment {
        switch alignment {
        case .left: return .leading
        case .center, .none: return .center
        case .right: return .trailing
        }
    }
    
    private func frameAlignmentForImage(_ alignment: ImageData.ImageAlignment?) -> Alignment {
        switch alignment {
        case .left: return .leading
        case .center, .none: return .center
        case .right: return .trailing
        }
    }
}

struct VideoView: View {
    let data: VideoData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Video player placeholder
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.primary)
                        
                        Text(data.title)
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if let duration = data.duration {
                            Text(formatDuration(duration))
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                    .padding()
                )
            
            if let description = data.description {
                Text(description)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .accessibilityLabel("Video: \(data.title)")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CodeBlockView: View {
    let data: CodeBlockData
    @State private var showCopyButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header with language and copy button
            HStack {
                if let language = data.language {
                    Text(language.uppercased())
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = data.code
                    // Show confirmation feedback
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .accessibilityLabel("Copy code")
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            
            // Code content
            ScrollView([.horizontal, .vertical]) {
                Text(data.code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct QuoteView: View {
    let data: QuoteData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // Quote mark
                Text("\"\"\"")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.primary)
                    .offset(y: -8)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(data.text)
                        .font(styleFont(data.style))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .italic()
                    
                    if let author = data.author {
                        HStack {
                            Text("— \(author)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            if let source = data.source {
                                Text("(\(source))")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    private func styleFont(_ style: QuoteData.QuoteStyle?) -> Font {
        switch style {
        case .emphasized: return DesignTokens.Typography.title3
        case .inspirational: return DesignTokens.Typography.headline
        case .normal, .none: return DesignTokens.Typography.body
        }
    }
}

struct CalloutView: View {
    let data: CalloutData
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: iconForType(data.type))
                .font(.title2)
                .foregroundColor(colorForType(data.type))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let title = data.title {
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(colorForType(data.type))
                }
                
                Text(data.text)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(backgroundColorForType(data.type))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(colorForType(data.type), lineWidth: 1)
                )
        )
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    private func iconForType(_ type: CalloutData.CalloutType) -> String {
        switch type {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .success: return "checkmark.circle"
        case .tip: return "lightbulb"
        }
    }
    
    private func colorForType(_ type: CalloutData.CalloutType) -> Color {
        switch type {
        case .info: return DesignTokens.Colors.primary
        case .warning: return DesignTokens.Colors.warning
        case .error: return DesignTokens.Colors.error
        case .success: return DesignTokens.Colors.success
        case .tip: return DesignTokens.Colors.secondary
        }
    }
    
    private func backgroundColorForType(_ type: CalloutData.CalloutType) -> Color {
        colorForType(type).opacity(0.1)
    }
}

struct DividerView: View {
    let data: DividerData
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: data.spacing ?? DesignTokens.Spacing.md)
            
            switch data.style {
            case .dotted:
                DottedLine()
            case .thick:
                Rectangle()
                    .fill(DesignTokens.Colors.glassBorder)
                    .frame(height: 3)
            case .decorative:
                HStack {
                    Rectangle()
                        .fill(DesignTokens.Colors.glassBorder)
                        .frame(height: 1)
                    
                    Image(systemName: "diamond")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                    
                    Rectangle()
                        .fill(DesignTokens.Colors.glassBorder)
                        .frame(height: 1)
                }
            case .line, .none:
                Rectangle()
                    .fill(DesignTokens.Colors.glassBorder)
                    .frame(height: 1)
            }
            
            Spacer()
                .frame(height: data.spacing ?? DesignTokens.Spacing.md)
        }
    }
}

struct DottedLine: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 300, y: 0))
        }
        .stroke(DesignTokens.Colors.glassBorder, style: StrokeStyle(lineWidth: 1, dash: [5]))
        .frame(height: 1)
    }
}

struct YouTubePlayerView: View {
    let data: YouTubeData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // YouTube player placeholder
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("YouTube Video")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text(data.videoId)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
            
            Text(data.title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            if let description = data.description {
                Text(description)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct InteractiveElementView: View {
    let data: InteractiveElementData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Interactive Element")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text("Type: \(data.type.rawValue)")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text(data.content)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            // Placeholder for actual interactive implementation
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .frame(height: 100)
                .overlay(
                    Text("🚧 Interactive element coming soon!")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                )
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct QuizView: View {
    let data: QuizData
    @State private var selectedAnswers: [UUID: String] = [:]
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let title = data.title {
                    Text(title)
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                if let description = data.description {
                    Text(description)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // Questions
            ForEach(data.questions) { question in
                QuizQuestionView(
                    question: question,
                    selectedAnswer: selectedAnswers[question.id] ?? "",
                    onAnswerSelected: { answer in
                        selectedAnswers[question.id] = answer
                    }
                )
            }
            
            // Submit button
            Button(action: {
                showResults = true
            }) {
                Text("Submit Quiz")
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
            }
            .disabled(selectedAnswers.count < data.questions.count)
            
            // Results
            if showResults {
                QuizResultsView(
                    questions: data.questions,
                    selectedAnswers: selectedAnswers
                )
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct QuizQuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: String
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(question.question)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            if let options = question.options {
                ForEach(options) { option in
                    Button(action: {
                        onAnswerSelected(option.text)
                    }) {
                        HStack {
                            Image(systemName: selectedAnswer == option.text ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(DesignTokens.Colors.primary)
                            
                            Text(option.text)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct QuizResultsView: View {
    let questions: [QuizQuestion]
    let selectedAnswers: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Quiz Results")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text("Score: \(correctAnswers)/\(questions.count)")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(scoreColor)
            
            ForEach(questions) { question in
                let userAnswer = selectedAnswers[question.id] ?? ""
                let isCorrect = userAnswer == question.correctAnswer
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                        
                        Text(question.question)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    
                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.leading, 24)
                    }
                }
            }
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var correctAnswers: Int {
        questions.filter { question in
            selectedAnswers[question.id] == question.correctAnswer
        }.count
    }
    
    private var scoreColor: Color {
        let percentage = Double(correctAnswers) / Double(questions.count)
        if percentage >= 0.8 { return DesignTokens.Colors.success }
        if percentage >= 0.6 { return DesignTokens.Colors.warning }
        return DesignTokens.Colors.error
    }
}

struct DiagramView: View {
    let data: DiagramData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if let title = data.title {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            // Diagram placeholder
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "flowchart")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.primary)
                        
                        Text("Diagram: \(data.type.rawValue)")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
            
            if let description = data.description {
                Text(description)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

struct TableView: View {
    let data: TableData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if let title = data.title {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(data.headers.indices, id: \.self) { index in
                            Text(data.headers[index])
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .fontWeight(.semibold)
                                .padding(DesignTokens.Spacing.sm)
                                .frame(minWidth: 100, maxWidth: .infinity)
                                .background(DesignTokens.Colors.glassBg)
                                .border(DesignTokens.Colors.glassBorder, width: 0.5)
                        }
                    }
                    
                    // Data rows
                    ForEach(data.rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(data.rows[rowIndex].indices, id: \.self) { colIndex in
                                Text(data.rows[rowIndex][colIndex])
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .padding(DesignTokens.Spacing.sm)
                                    .frame(minWidth: 100, maxWidth: .infinity)
                                    .background(
                                        shouldStripe(data.style) && rowIndex % 2 == 1 
                                            ? DesignTokens.Colors.glassBg.opacity(0.5)
                                            : Color.clear
                                    )
                                    .border(DesignTokens.Colors.glassBorder, width: 0.5)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    private func shouldStripe(_ style: TableData.TableStyle?) -> Bool {
        style == .striped
    }
}

struct SpacerView: View {
    let data: SpacerData
    
    var body: some View {
        Spacer()
            .frame(height: data.height)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            LessonBlockView(block: LessonBlock(
                type: .heading,
                data: .heading(HeadingData(text: "Sample Heading", level: 1, style: .normal)),
                order: 0
            ))
            
            LessonBlockView(block: LessonBlock(
                type: .paragraph,
                data: .paragraph(ParagraphData(text: "This is a sample paragraph to demonstrate the paragraph component.", style: .normal)),
                order: 1
            ))
            
            LessonBlockView(block: LessonBlock(
                type: .callout,
                data: .callout(CalloutData(text: "This is a tip callout!", type: .tip, title: "Pro Tip", icon: "lightbulb")),
                order: 2
            ))
        }
        .padding()
    }
    .background(DesignTokens.Colors.primaryBg)
}