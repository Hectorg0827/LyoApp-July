import SwiftUI

// MARK: - Learning Resource Cards
/// Different visual representations for a learning resource.

// MARK: - Featured Card (Large)
struct LearningResourceFeaturedCard: View {
    let resource: LearningResource
    
    var body: some View {
        VStack(alignment: .leading) {
            // Image with overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: resource.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: resource.contentType.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 180)
                .clipped()
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.category ?? "General")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    Text(resource.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Label(resource.estimatedDuration ?? "N/A", systemImage: "clock")
                    Spacer()
                    if let rating = resource.rating {
                        Label("\(rating, specifier: "%.1f")", systemImage: "star.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    static var skeleton: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.white.opacity(0.1))
            .frame(width: 320, height: 280)
    }
}

// MARK: - Standard Card (Grid)
struct LearningResourceCard: View {
    let resource: LearningResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: resource.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: resource.contentType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 100)
            .clipped()
            .cornerRadius(15)
            
            Text(resource.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(resource.category ?? "General")
                .font(.caption2)
                .foregroundColor(.cyan)
            
            HStack {
                Label(resource.estimatedDuration ?? "N/A", systemImage: "clock")
                Spacer()
                if let rating = resource.rating {
                    Label("\(rating, specifier: "%.1f")", systemImage: "star.fill")
                }
            }
            .font(.caption2)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    static var skeleton: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .frame(width: 160, height: 200)
    }
}

// MARK: - Row (List)
struct LearningResourceRow: View {
    let resource: LearningResource
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: resource.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: resource.contentType.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 100, height: 80)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(resource.category ?? "General")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Spacer()
                    Label(resource.estimatedDuration ?? "N/A", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    static var skeleton: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white.opacity(0.1))
            .frame(height: 100)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            LearningResourceFeaturedCard(resource: LearningResource.sampleResources[0])
            LearningResourceCard(resource: LearningResource.sampleResources[1])
            LearningResourceRow(resource: LearningResource.sampleResources[2])
        }
        .padding()
    }
    .preferredColorScheme(.dark)
    .background(Color.black)
}
