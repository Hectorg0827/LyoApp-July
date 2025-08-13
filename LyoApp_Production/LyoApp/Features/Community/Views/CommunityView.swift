import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.communities.isEmpty {
                        ForEach(0..<3) { _ in
                            CommunityCardSkeleton()
                        }
                    } else {
                        ForEach(viewModel.communities) { community in
                            CommunityCard(community: community)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshCommunities()
            }
            .navigationTitle("Communities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Create community action
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCommunities()
            }
        }
    }
}

struct CommunityCard: View {
    let community: Community
    @State private var isMember = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: community.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(community.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("\(community.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(community.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    isMember.toggle()
                }) {
                    Text(isMember ? "Joined" : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isMember ? Color.gray.opacity(0.2) : Color.blue)
                        .foregroundColor(isMember ? .primary : .white)
                        .cornerRadius(16)
                }
            }
            
            Text(community.description)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            isMember = community.isMember ?? false
        }
    }
}

struct CommunityCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 18)
                        .frame(maxWidth: 140)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(maxWidth: 80)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(maxWidth: 60)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 24)
                    .cornerRadius(16)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 50)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shimmer()
    }
}

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var communities: [Community] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadCommunities() async {
        isLoading = true
        
        do {
            let communitiesResponse: CommunitiesResponse = try await networkManager.get(
                endpoint: BackendConfig.Endpoints.communities,
                responseType: CommunitiesResponse.self
            )
            communities = communitiesResponse.communities
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshCommunities() async {
        await loadCommunities()
    }
}

struct CommunitiesResponse: Codable {
    let communities: [Community]
    let totalCount: Int
    let hasMore: Bool
}
