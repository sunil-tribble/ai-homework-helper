import SwiftUI

struct SolutionView: View {
    let problem: Problem
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false
    @State private var successAnimation = false
    @EnvironmentObject var userManager: UserManager
    @State private var showStreakCelebration = false
    @State private var showStepAnimation = false
    @State private var currentAnimatedStep = 0
    @State private var stepAnimationProgress: CGFloat = 0
    @State private var showingResources = false
    @StateObject private var openAIService = OpenAIService()
    @State private var resources: [LearningResource] = []
    @State private var showingHints = true
    @State private var currentHintIndex = 0
    @State private var hints: [String] = []
    @State private var showingEthicalNudge = false
    @State private var showingMathVisualizer = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Success animation
                    if successAnimation {
                        successAnimationView
                    }
                    
                    // Problem Header
                    problemHeader
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    // Solution Content with Ethical Learning
                    if showingHints && !hints.isEmpty {
                        hintsSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)
                    } else if showStepAnimation {
                        animatedSolutionContent
                    } else {
                        solutionContent
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)
                    }
                    
                    // Resources Section
                    if !resources.isEmpty {
                        resourcesSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: appearAnimation)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: appearAnimation)
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
            // Show success animation briefly
            successAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    successAnimation = false
                }
            }
            
            // Check if we should show streak celebration
            if userManager.showStreakCelebration {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showStreakCelebration = true
                    userManager.showStreakCelebration = false
                }
            }
            
            // Load curated resources and hints
            Task {
                do {
                    resources = try await openAIService.getCuratedResources(
                        for: problem.questionText, 
                        subject: problem.subject
                    )
                    
                    // Generate hints for ethical learning
                    hints = generateHints(for: problem)
                    
                    // Show ethical nudge for first-time users
                    if userManager.totalSolves == 1 && !userManager.hasSeenEthicalNudge {
                        showingEthicalNudge = true
                    }
                } catch {
                    print("Failed to load resources: \(error)")
                }
            }
        }
        .sheet(isPresented: $showStreakCelebration) {
            StreakCelebrationView(streak: userManager.currentStreak)
        }
        .sheet(isPresented: $showingEthicalNudge) {
            EthicalLearningNudgeView()
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingMathVisualizer) {
            MathVisualizerView(expression: problem.questionText)
        }
        .navigationTitle("Solution")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
    }
    
    private var problemHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subject and Difficulty
            HStack {
                Label(problem.subject.rawValue, systemImage: problem.subject.icon)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(problem.subject.color.opacity(0.1))
                    .foregroundColor(problem.subject.color)
                    .cornerRadius(20)
                
                Text(problem.difficulty.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(problem.difficulty.color.opacity(0.1))
                    .foregroundColor(problem.difficulty.color)
                    .cornerRadius(20)
                
                Spacer()
                
                Text(problem.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Problem Image
            if let imageData = problem.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
            
            // Question Text
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.headline)
                
                Text(problem.questionText)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
            }
        }
    }
    
    private var solutionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Solution")
                    .font(.headline)
                
                Spacer()
                
                // Math visualization button
                if problem.subject == .math {
                    Button(action: { showingMathVisualizer = true }) {
                        Label("Visualize", systemImage: "chart.xyaxis.line")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                // Toggle for step animation
                if problem.subject == .math && problem.solution.contains("Step") {
                    Button(action: { 
                        showStepAnimation.toggle()
                        if showStepAnimation {
                            startStepAnimation()
                        }
                    }) {
                        Label(showStepAnimation ? "Text View" : "Animated View", 
                              systemImage: showStepAnimation ? "text.alignleft" : "play.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Solution Text with Markdown Support
            Text(problem.solution)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    private var animatedSolutionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .symbolEffect(.bounce, value: currentAnimatedStep)
                Text("Animated Solution")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { 
                    showStepAnimation = false
                }) {
                    Label("Text View", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Parse and animate steps
            let steps = parseSteps(from: problem.solution)
            
            ForEach(0..<steps.count, id: \.self) { index in
                let isVisible = currentAnimatedStep > index
                let progress = index == currentAnimatedStep - 1 ? stepAnimationProgress : (currentAnimatedStep > index ? 1.0 : 0.0)
                
                StepAnimationView(
                    step: steps[index],
                    stepNumber: index + 1,
                    isVisible: isVisible,
                    progress: progress
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .identity
                ))
            }
            
            if currentAnimatedStep >= steps.count {
                // Final answer highlight
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                        .symbolEffect(.bounce, value: currentAnimatedStep)
                    
                    Text("Solution Complete!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                )
                .scaleEffect(1.05)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func parseSteps(from solution: String) -> [String] {
        // Simple parsing - in production, use more sophisticated parsing
        let lines = solution.components(separatedBy: "\n")
        var steps: [String] = []
        var currentStep = ""
        
        for line in lines {
            if line.lowercased().contains("step") && !currentStep.isEmpty {
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                currentStep = line
            } else {
                currentStep += "\n" + line
            }
        }
        
        if !currentStep.isEmpty {
            steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return steps.isEmpty ? [solution] : steps
    }
    
    private func startStepAnimation() {
        currentAnimatedStep = 0
        stepAnimationProgress = 0
        
        let steps = parseSteps(from: problem.solution)
        
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentAnimatedStep = i + 1
                }
                
                // Animate progress
                withAnimation(.easeInOut(duration: 1.5)) {
                    stepAnimationProgress = 1.0
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingShareSheet = true }) {
                Label("Share Solution", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Button(action: {
                // Navigate to scanner for new problem
                dismiss()
            }) {
                Label("Solve Another Problem", systemImage: "plus.circle")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        }
                    )
            }
        }
    }
    
    private func createShareText() -> String {
        """
        Problem: \(problem.questionText)
        
        Subject: \(problem.subject.rawValue)
        
        Solution:
        \(problem.solution)
        
        Solved with AI Homework Helper
        """
    }
    
    private var successAnimationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(1.2)
            
            Text("Solution Generated!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(30)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.5), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .shadow(color: Color.green.opacity(0.3), radius: 15, x: 0, y: 10)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.purple)
                Text("Related Resources")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingResources.toggle() }) {
                    Image(systemName: showingResources ? "chevron.up" : "chevron.down")
                        .foregroundColor(.purple)
                }
            }
            
            if showingResources {
                VStack(spacing: 12) {
                    ForEach(resources, id: \.title) { resource in
                        ResourceCard(resource: resource)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            // Auto-expand resources for better discovery
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingResources = true
                }
            }
        }
    }
    
    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "lightbulb.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Text("Learning Hints")
                    .font(.headline)
                
                Spacer()
                
                if currentHintIndex < hints.count - 1 || showingHints {
                    Text("\(currentHintIndex + 1)/\(hints.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                }
            }
            
            // Current hint with animation
            if currentHintIndex < hints.count {
                VStack(alignment: .leading, spacing: 12) {
                    Text(hints[currentHintIndex])
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                    // Hint navigation
                    HStack(spacing: 16) {
                        if currentHintIndex < hints.count - 1 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    currentHintIndex += 1
                                }
                            }) {
                                Label("Next Hint", systemImage: "arrow.right.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                            }
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showingHints = false
                            }
                        }) {
                            Label(currentHintIndex == hints.count - 1 ? "Show Full Solution" : "Skip to Solution", 
                                  systemImage: "eye.fill")
                                .font(.headline)
                                .foregroundColor(currentHintIndex == hints.count - 1 ? .white : .blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    currentHintIndex == hints.count - 1 ?
                                    AnyView(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    ) :
                                    AnyView(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                                )
                                .cornerRadius(25)
                        }
                    }
                }
            }
            
            // Learning tip
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Try solving with these hints first - it helps you learn better!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.05))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func generateHints(for problem: Problem) -> [String] {
        // Generate contextual hints based on problem type
        switch problem.subject {
        case .math:
            return generateMathHints(for: problem)
        case .science:
            return generateScienceHints(for: problem)
        case .english:
            return generateEnglishHints(for: problem)
        case .history:
            return generateHistoryHints(for: problem)
        case .physics, .chemistry, .biology, .computerScience, .programming, .other:
            return generateGeneralHints(for: problem)
        }
    }
    
    private func generateMathHints(for problem: Problem) -> [String] {
        let questionLower = problem.questionText.lowercased()
        
        if questionLower.contains("derivative") {
            return [
                "Remember the power rule: d/dx(x^n) = n·x^(n-1)",
                "For each term, apply the derivative rules separately",
                "Don't forget that the derivative of a constant is 0"
            ]
        } else if questionLower.contains("integral") {
            return [
                "Think about what function would give you this when differentiated",
                "Remember to add the constant of integration (+C)",
                "Try using substitution if the integral looks complex"
            ]
        } else if questionLower.contains("equation") {
            return [
                "First, try to isolate the variable on one side",
                "Remember to perform the same operation on both sides",
                "Check your answer by substituting it back into the original equation"
            ]
        } else if questionLower.contains("factor") {
            return [
                "Look for common factors first",
                "Try grouping terms that might have something in common",
                "Remember special patterns like difference of squares: a² - b² = (a+b)(a-b)"
            ]
        } else {
            return [
                "Identify what the problem is asking for",
                "List what information you're given",
                "Think about which formulas or methods apply to this type of problem"
            ]
        }
    }
    
    private func generateScienceHints(for problem: Problem) -> [String] {
        let questionLower = problem.questionText.lowercased()
        
        if questionLower.contains("physics") || questionLower.contains("force") || questionLower.contains("motion") {
            return [
                "Start by identifying all the forces acting on the object",
                "Remember Newton's laws of motion",
                "Draw a free body diagram to visualize the problem"
            ]
        } else if questionLower.contains("chemistry") || questionLower.contains("reaction") {
            return [
                "Balance the equation by counting atoms on each side",
                "Remember conservation of mass - atoms can't be created or destroyed",
                "Check that charges are balanced if it's a redox reaction"
            ]
        } else if questionLower.contains("biology") || questionLower.contains("cell") {
            return [
                "Think about the function of each organelle or structure",
                "Consider how this relates to the larger biological system",
                "Remember the relationship between structure and function"
            ]
        } else {
            return [
                "Identify the scientific principle involved",
                "Think about cause and effect relationships",
                "Consider what variables might affect the outcome"
            ]
        }
    }
    
    private func generateEnglishHints(for problem: Problem) -> [String] {
        return [
            "Consider the context and purpose of the text",
            "Look for literary devices or rhetorical strategies",
            "Think about the author's intended message or theme"
        ]
    }
    
    private func generateHistoryHints(for problem: Problem) -> [String] {
        return [
            "Consider the historical context and time period",
            "Think about cause and effect relationships between events",
            "Remember to consider multiple perspectives on historical events"
        ]
    }
    
    private func generateGeneralHints(for problem: Problem) -> [String] {
        return [
            "Break down the problem into smaller parts",
            "Identify what information you have and what you need to find",
            "Think about similar problems you've solved before"
        ]
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct StreakCelebrationView: View {
    let streak: Int
    @Environment(\.dismiss) private var dismiss
    @State private var animateConfetti = false
    @State private var animateScale = false
    @State private var fireworksAnimation = false
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var streakMessage: String {
        switch streak {
        case 3: return "3-Day Streak! You're building a habit!"
        case 7: return "One Week Strong! Keep it up!"
        case 14: return "Two Weeks! You're unstoppable!"
        case 30: return "30 Days! You're a true scholar!"
        case 50: return "50 Days! Legendary dedication!"
        case 100: return "100 DAYS! You're a GENIUS!"
        default: return "Amazing streak!"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Confetti effect
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animateConfetti ? UIScreen.main.bounds.height + 100 : -100
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...0.5)),
                        value: animateConfetti
                    )
            }
            
            // Fireworks for major milestones
            if fireworksAnimation && [7, 30, 50, 100].contains(streak) {
                ZStack {
                    ForEach(0..<5) { index in
                        FireworkEffect()
                            .position(
                                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                                y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 200)
                            )
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.3),
                                value: fireworksAnimation
                            )
                    }
                }
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Fire animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange, Color.red.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                        .scaleEffect(animateScale ? 1.3 : 1.0)
                    
                    // Streak number
                    VStack {
                        Text("\(streak)")
                            .font(.system(size: 100, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("DAY STREAK!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateScale ? 1.1 : 0.8)
                }
                
                Text(streakMessage)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animateScale ? 1 : 0)
                
                // Badge earned
                HStack {
                    Image(systemName: "rosette")
                        .font(.title2)
                    Text("Badge Earned!")
                        .font(.headline)
                }
                .foregroundColor(.yellow)
                .padding()
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                )
                .scaleEffect(animateScale ? 1 : 0)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Continue Learning")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .scaleEffect(animateScale ? 1 : 0.8)
            }
        }
        .onAppear {
            animateConfetti = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateScale = true
            }
            
            // Play celebration haptics and sound
            hapticManager.playStreakCelebration()
            soundManager.play(.streakCelebration)
            
            // Trigger fireworks for major milestones
            if [7, 30, 50, 100].contains(streak) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    fireworksAnimation = true
                }
            }
        }
    }
}

struct ConfettiPiece: View {
    let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]
    let size = CGFloat.random(in: 8...16)
    let rotation = Double.random(in: 0...360)
    
    var body: some View {
        RoundedRectangle(cornerRadius: size / 4)
            .fill(colors.randomElement() ?? .blue)
            .frame(width: size, height: size * 1.5)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(
                .degrees(Double.random(in: 0...360)),
                axis: (x: Double.random(in: 0...1), y: Double.random(in: 0...1), z: Double.random(in: 0...1))
            )
    }
}

#Preview {
    NavigationStack {
        SolutionView(
            problem: Problem(
                questionText: "What is the derivative of x^2 + 3x - 5?",
                solution: """
                To find the derivative of f(x) = x² + 3x - 5, we'll use the power rule.
                
                Step 1: Apply the power rule to each term
                - d/dx(x²) = 2x
                - d/dx(3x) = 3
                - d/dx(-5) = 0 (derivative of a constant is 0)
                
                Step 2: Combine the results
                f'(x) = 2x + 3
                
                Therefore, the derivative is f'(x) = 2x + 3
                """,
                subject: .math,
                difficulty: .medium
            )
        )
        .environmentObject(UserManager())
    }
}