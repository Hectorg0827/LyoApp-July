import SwiftUI

/**
 * EdX Course Browser View
 * Specialized UI for browsing edX courses with university and subject filtering
 */
struct EdXCourseBrowserView: View {
    @StateObject private var edxService = EdXCoursesService()
    @State private var selectedUniversity: EdXUniversity?
    @State private var selectedSubject: EdXSubjectCategory?
    @State private var searchText = ""
    @State private var courses: [Course] = []
    @State private var universities = [EdXUniversity]()
    @State private var subjects = [EdXSubjectCategory]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with branding
                edxHeaderView
                
                // Search and filters
                searchAndFiltersView
                
                // Course content
                if isLoading {
                    loadingView
                } else if courses.isEmpty {
                    emptyStateView
                } else {
                    courseGridView
                }
                
                Spacer()
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("edX Courses")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadInitialData()
            }
        }
    }
    
    // MARK: - Header View
    private var edxHeaderView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                // edX logo placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("edX")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("edX Free Courses")
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("World-class education from top universities")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // Statistics
            HStack(spacing: DesignTokens.Spacing.lg) {
                StatisticView(title: "Universities", value: "100+", color: .blue)
                StatisticView(title: "Courses", value: "3000+", color: .green)
                StatisticView(title: "Students", value: "40M+", color: .purple)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Search and Filters
    private var searchAndFiltersView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Search courses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        loadFeaturedCourses()
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
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
            
            // University filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(universities) { university in
                        UniversityFilterChip(
                            university: university,
                            isSelected: selectedUniversity?.id == university.id
                        ) {
                            selectedUniversity = selectedUniversity?.id == university.id ? nil : university
                            filterByUniversity()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
            
            // Subject filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(subjects) { subject in
                        SubjectFilterChip(
                            subject: subject,
                            isSelected: selectedSubject?.id == subject.id
                        ) {
                            selectedSubject = selectedSubject?.id == subject.id ? nil : subject
                            filterBySubject()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    // MARK: - Course Grid
    private var courseGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.md) {
                ForEach(courses) { course in
                    EdXCourseCard(course: course) {
                        // Handle course selection
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
    
    // MARK: - Loading and Empty States
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading edX courses...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "graduationcap")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("No courses found")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Try adjusting your search or filters")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Show All Courses") {
                clearFilters()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(.white)
            .padding()
            .background(DesignTokens.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() {
        universities = edxService.getPopularUniversities()
        subjects = edxService.getSubjectCategories()
        loadFeaturedCourses()
    }
    
    private func loadFeaturedCourses() {
        isLoading = true
        Task {
            do {
                courses = try await edxService.getFeaturedCourses()
            } catch {
                print("Failed to load featured courses: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        Task {
            do {
                courses = try await edxService.searchFreeCourses(query: searchText)
            } catch {
                print("Search failed: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func filterByUniversity() {
        guard let university = selectedUniversity else {
            loadFeaturedCourses()
            return
        }
        
        isLoading = true
        Task {
            do {
                courses = try await edxService.getCoursesByUniversity(university.slug)
            } catch {
                print("University filter failed: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func filterBySubject() {
        guard let subject = selectedSubject else {
            loadFeaturedCourses()
            return
        }
        
        isLoading = true
        Task {
            do {
                courses = try await edxService.getCoursesBySubject(subject.slug)
            } catch {
                print("Subject filter failed: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func clearFilters() {
        selectedUniversity = nil
        selectedSubject = nil
        searchText = ""
        loadFeaturedCourses()
    }
}

// MARK: - Supporting Views

struct StatisticView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignTokens.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
}

struct UniversityFilterChip: View {
    let university: EdXUniversity
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                AsyncImage(url: URL(string: university.logoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 20, height: 20)
                
                Text(university.name)
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                
                Text("(\(university.courseCount))")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
            )
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubjectFilterChip: View {
    let subject: EdXSubjectCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: subject.icon)
                    .font(.system(size: 14))
                
                Text(subject.name)
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                
                Text("(\(subject.courseCount))")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
            )
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EdXCourseCard: View {
    let course: Course
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Course thumbnail
                AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "graduationcap")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // Course title
                    Text(course.title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Instructor
                    Text(course.instructor)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                    
                    // Category and rating
                    HStack {
                        Text(course.category)
                            .font(DesignTokens.Typography.caption2)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                            .foregroundColor(DesignTokens.Colors.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", course.rating))
                                .font(DesignTokens.Typography.caption2)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.sm)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EdXCourseBrowserView()
}
