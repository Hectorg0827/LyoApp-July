import SwiftUI

struct CommunityView: View {
    @State private var selectedTab = 0
    @State private var communities = Community.sampleCommunities
    @State private var discussions = Discussion.sampleDiscussions
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView(showingStoryDrawer: .constant(false))
                
                // Tab Selection
                Picker("Community Tabs", selection: $selectedTab) {
                    Text("Communities").tag(0)
                    Text("Discussions").tag(1)
                    Text("Events").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(DesignTokens.Spacing.md)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Communities Tab
                    communitiesSection
                        .tag(0)
                    
                    // Discussions Tab
                    discussionsSection
                        .tag(1)
                    
                    // Events Tab
                    eventsSection
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Handle create community/discussion
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
            }
        }
    }
    
    private var communitiesSection: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // Featured Community
                featuredCommunityCard
                
                // My Communities
                myCommunitiesSection
                
                // Discover Communities
                discoverCommunitiesSection
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
    
    private var featuredCommunityCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Featured Community")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                DesignSystem.Badge(text: "New", style: .secondary)
            }
            
            Text("SwiftUI Developers")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(.white)
            
            Text("Connect with fellow SwiftUI developers, share projects, and learn together")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
            
            HStack {
                Label("2.5K members", systemImage: "person.3.fill")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Button("Join Community") {
                    // Handle join community
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(.white)
                )
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Colors.primaryGradient)
        )
    }
    
    private var myCommunitiesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("My Communities")
                .font(DesignTokens.Typography.title3)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
                ForEach(communities.prefix(4)) { community in
                    CommunityCard(community: community, isJoined: true)
                }
            }
        }
    }
    
    private var discoverCommunitiesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Discover Communities")
                .font(DesignTokens.Typography.title3)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
                ForEach(communities.suffix(4)) { community in
                    CommunityCard(community: community, isJoined: false)
                }
            }
        }
    }
    
    private var discussionsSection: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(discussions) { discussion in
                    DiscussionCard(discussion: discussion)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
    
    private var eventsSection: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(CommunityEvent.sampleEvents) { event in
                    EventCard(event: event)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
}

// MARK: - Community Card
struct CommunityCard: View {
    let community: Community
    let isJoined: Bool
    @State private var joined: Bool
    
    init(community: Community, isJoined: Bool) {
        self.community = community
        self.isJoined = isJoined
        self._joined = State(initialValue: isJoined)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Community Icon
            HStack {
                Image(systemName: community.icon)
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(DesignTokens.Colors.primary.opacity(0.1))
                    )
                
                Spacer()
                
                if joined {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(community.name)
                    .font(DesignTokens.Typography.bodyMedium)
                    .lineLimit(1)
                
                Text(community.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                    .lineLimit(2)
                
                HStack {
                    Label("\(community.memberCount)", systemImage: "person.3.fill")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                    
                    Spacer()
                    
                    Button(joined ? "Joined" : "Join") {
                        withAnimation(DesignTokens.Animations.bouncy) {
                            joined.toggle()
                        }
                    }
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(joined ? DesignTokens.Colors.primary : .white)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .fill(joined ? DesignTokens.Colors.background : DesignTokens.Colors.primary)
                            .strokeBorder(DesignTokens.Colors.primary, lineWidth: joined ? 1 : 0)
                    )
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Discussion Card
struct DiscussionCard: View {
    let discussion: Discussion
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header
            HStack {
                DesignSystem.Avatar(
                    imageURL: discussion.author.profileImageURL,
                    name: discussion.author.fullName,
                    size: 35
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(discussion.author.fullName)
                        .font(DesignTokens.Typography.caption)
                        .fontWeight(.medium)
                    
                    Text(timeAgo(from: discussion.createdAt))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.secondaryLabel)
                }
                
                Spacer()
                
                DesignSystem.Badge(text: discussion.community.name, style: .primary)
            }
            
            // Content
            Text(discussion.title)
                .font(DesignTokens.Typography.bodyMedium)
                .lineLimit(2)
            
            Text(discussion.content)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                .lineLimit(3)
            
            // Tags
            if !discussion.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(discussion.tags, id: \.self) { tag in
                            DesignSystem.Badge(text: "#\(tag)", style: .secondary)
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                Button {
                    // Handle like
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "heart")
                        Text("\(discussion.likes)")
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                }
                
                Button {
                    // Handle reply
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                        Text("\(discussion.replies)")
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                }
                
                Spacer()
                
                Button {
                    // Handle bookmark
                } label: {
                    Image(systemName: "bookmark")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.secondaryLabel)
                }
            }
        }
        .cardStyle()
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: CommunityEvent
    @State private var isInterested = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Event Image
            AsyncImage(url: URL(string: event.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.gray200)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(event.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .lineLimit(2)
                
                Text(event.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                    .lineLimit(3)
                
                HStack {
                    Text(event.date, style: .date)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                    
                    Spacer()
                    
                    Button(isInterested ? "Interested" : "Interested?") {
                        withAnimation(DesignTokens.Animations.bouncy) {
                            isInterested.toggle()
                        }
                    }
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(isInterested ? DesignTokens.Colors.primary : .white)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .fill(isInterested ? DesignTokens.Colors.background : DesignTokens.Colors.primary)
                            .strokeBorder(DesignTokens.Colors.primary, lineWidth: isInterested ? 1 : 0)
                    )
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    CommunityView()
}
