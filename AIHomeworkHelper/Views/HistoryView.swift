import SwiftUI

struct HistoryView: View {
    @StateObject private var problemStorage = ProblemStorage.shared
    @State private var selectedSubject: Subject?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var problemToDelete: Problem?
    @State private var appearAnimation = false
    @State private var deleteAnimation = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var filteredProblems: [Problem] {
        let problems = selectedSubject != nil ? 
            problemStorage.getProblemsBySubject(selectedSubject!) : 
            problemStorage.problems
        
        if searchText.isEmpty {
            return problems
        } else {
            return problems.filter { 
                $0.questionText.localizedCaseInsensitiveContains(searchText) ||
                $0.solution.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Subject Filter
                subjectFilter
                
                // Problems List
                if filteredProblems.isEmpty {
                    emptyStateView
                } else {
                    problemsList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search problems...")
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
            .alert("Delete Problem", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let problem = problemToDelete {
                        problemStorage.deleteProblem(problem)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this problem? This action cannot be undone.")
            }
        }
    }
    
    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedSubject == nil,
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSubject = nil
                    }
                    hapticManager.selection()
                    soundManager.play(.tap)
                }
                
                ForEach(Subject.allCases, id: \.self) { subject in
                    FilterChip(
                        title: subject.rawValue,
                        icon: subject.icon,
                        isSelected: selectedSubject == subject,
                        color: subject.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSubject = subject
                        }
                        hapticManager.selection()
                        soundManager.play(.tap)
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private var problemsList: some View {
        List {
            ForEach(Array(filteredProblems.enumerated()), id: \.element.id) { index, problem in
                NavigationLink(destination: SolutionView(problem: problem)) {
                    ProblemRow(problem: problem)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(x: appearAnimation ? 0 : -50)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: appearAnimation
                        )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        problemToDelete = problem
                        showingDeleteAlert = true
                        hapticManager.notification(.warning)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    ShareLink(item: createShareText(for: problem)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        EmptyStateView(type: searchText.isEmpty ? .noHistory : .noResults) {
            if searchText.isEmpty {
                // Navigate to scanner
            } else {
                searchText = ""
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .transition(.opacity.combined(with: .scale))
    }
    
    private func createShareText(for problem: Problem) -> String {
        """
        Problem: \(problem.questionText)
        Subject: \(problem.subject.rawValue)
        
        Solution:
        \(problem.solution)
        
        Solved with AI Homework Helper
        """
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        color
                            .cornerRadius(20)
                            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
                    } else {
                        Color.gray.opacity(0.2)
                            .cornerRadius(20)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct ProblemRow: View {
    let problem: Problem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(problem.subject.rawValue, systemImage: problem.subject.icon)
                    .font(.caption)
                    .foregroundColor(problem.subject.color)
                
                Spacer()
                
                Text(problem.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Question Preview
            Text(problem.questionText)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            // Solution Preview
            Text(problem.solution)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Difficulty Badge
            HStack {
                Text(problem.difficulty.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(problem.difficulty.color.opacity(0.1))
                    .foregroundColor(problem.difficulty.color)
                    .cornerRadius(6)
                
                Spacer()
                
                if problem.imageData != nil {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered.toggle()
            }
            HapticManager.shared.impact(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHovered = false
            }
        }
    }
}

#Preview {
    HistoryView()
}