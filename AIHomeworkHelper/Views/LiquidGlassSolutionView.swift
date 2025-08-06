import SwiftUI

struct LiquidGlassSolutionView: View {
    let problem: Problem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var appearAnimation = false
    @State private var stepRevealProgress: [Bool] = []
    @State private var showingHints = true
    @State private var currentHintIndex = 0
    @State private var showingShareSheet = false
    @State private var selectedStep: Int?
    @State private var interactionDepth: CGFloat = 0
    @StateObject private var hapticManager = HapticManager.shared
    
    var body: some View {
        ZStack {
            // Adaptive background
            backgroundLayer
            
            ScrollView {
                VStack(spacing: 24) {
                    // Problem context card
                    problemContextCard
                        .liquidTransition(isVisible: appearAnimation)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appearAnimation)
                    
                    // Solution presentation
                    if showingHints && !generateHints().isEmpty {
                        hintsPresentation
                    } else {
                        solutionPresentation
                    }
                    
                    // Action buttons
                    actionSection
                }
                .padding()
            }
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
        .onAppear {
            appearAnimation = true
            initializeStepReveals()
            hapticManager.playLiquidFlow()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
    }
    
    private var backgroundLayer: some View {
        ZStack {
            // Base gradient that responds to solution correctness
            LinearGradient(
                colors: [
                    Color.green.opacity(0.05),
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Success particles
            if appearAnimation {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .offset(
                            x: CGFloat.random(in: -150...150),
                            y: CGFloat.random(in: -200...200)
                        )
                        .scaleEffect(appearAnimation ? CGFloat.random(in: 0.8...1.5) : 0)
                        .opacity(appearAnimation ? 0 : 1)
                        .animation(
                            .easeOut(duration: 2)
                                .delay(Double(index) * 0.2),
                            value: appearAnimation
                        )
                }
            }
        }
    }
    
    private var problemContextCard: some View {
        DepthCard(depth: .floating) {
            VStack(alignment: .leading, spacing: 16) {
                // Subject and difficulty badges
                HStack {
                    SubjectBadge(subject: problem.subject)
                    DifficultyBadge(difficulty: problem.difficulty)
                    Spacer()
                    TimeBadge(date: problem.createdAt)
                }
                
                // Question presentation
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Question")
                            .font(.headline)
                    }
                    
                    Text(problem.questionText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(ConditionalLiquidGlass(style: .ultraThin, luminosity: 0.8))
                        .cornerRadius(12)
                }
                
                // Image if available
                if let imageData = problem.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
    }
    
    private var solutionPresentation: some View {
        VStack(spacing: 20) {
            // Solution header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .symbolEffect(.pulse.byLayer, options: .repeating)
                Text("Solution")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            // Parse solution into steps
            let steps = parseSolutionSteps()
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                StepCard(
                    step: step,
                    stepNumber: index + 1,
                    isRevealed: index < stepRevealProgress.count && stepRevealProgress[index],
                    isSelected: selectedStep == index,
                    totalSteps: steps.count
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedStep = selectedStep == index ? nil : index
                        hapticManager.playGlassTouch()
                    }
                }
                .onAppear {
                    // Staggered reveal animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            if index < stepRevealProgress.count {
                                stepRevealProgress[index] = true
                            }
                        }
                    }
                }
            }
            
            // Final answer emphasis
            if let finalAnswer = extractFinalAnswer(from: problem.solution) {
                FinalAnswerCard(answer: finalAnswer)
                    .liquidTransition(isVisible: stepRevealProgress.allSatisfy { $0 })
            }
        }
    }
    
    private var hintsPresentation: some View {
        VStack(spacing: 20) {
            MorphingGlassContainer {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        Text("Learning Hints")
                            .font(.headline)
                        Spacer()
                        
                        // Progress indicator
                        HintProgressIndicator(
                            current: currentHintIndex + 1,
                            total: generateHints().count
                        )
                    }
                    
                    // Current hint with glass effect
                    let hints = generateHints()
                    if currentHintIndex < hints.count {
                        Text(hints[currentHintIndex])
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(ConditionalLiquidGlass(style: .thin, luminosity: 1.2))
                            .cornerRadius(12)
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentHintIndex < hints.count - 1 {
                            LiquidButton(
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentHintIndex += 1
                                        hapticManager.playRipple(intensity: 0.4)
                                    }
                                },
                                style: .primary
                            ) {
                                HStack {
                                    Text("Next Hint")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                            }
                        }
                        
                        LiquidButton(
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showingHints = false
                                    hapticManager.playLiquidFlow()
                                }
                            },
                            style: currentHintIndex == hints.count - 1 ? .primary : .ghost
                        ) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text(currentHintIndex == hints.count - 1 ? "Show Full Solution" : "Skip to Solution")
                            }
                            .font(.headline)
                            .foregroundColor(currentHintIndex == hints.count - 1 ? .white : .blue)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Main actions
            HStack(spacing: 16) {
                LiquidButton(
                    action: { showingShareSheet = true },
                    style: .secondary
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }
                
                LiquidButton(
                    action: { dismiss() },
                    style: .primary
                ) {
                    Label("New Problem", systemImage: "plus.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Learning resources
            if problem.subject == .math {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Visualize Solution")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding()
                    .modifier(ConditionalLiquidGlass(style: .ultraThin, luminosity: 0.6))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func initializeStepReveals() {
        let stepCount = parseSolutionSteps().count
        stepRevealProgress = Array(repeating: false, count: stepCount)
    }
    
    private func parseSolutionSteps() -> [String] {
        let lines = problem.solution.components(separatedBy: "\n")
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
        
        return steps.isEmpty ? [problem.solution] : steps
    }
    
    private func extractFinalAnswer(from solution: String) -> String? {
        let patterns = ["answer:", "therefore:", "solution:", "result:", "="]
        let lowercased = solution.lowercased()
        
        for pattern in patterns {
            if let range = lowercased.range(of: pattern), range.upperBound < solution.endIndex {
                let afterPattern = String(solution[range.upperBound...])
                let lines = afterPattern.components(separatedBy: .newlines)
                if let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !firstLine.isEmpty {
                    return firstLine
                }
            }
        }
        
        return nil
    }
    
    private func generateHints() -> [String] {
        // Simplified hint generation
        switch problem.subject {
        case .math:
            return [
                "Break down the problem into smaller parts",
                "Identify what formulas or methods apply",
                "Try working through a simpler example first"
            ]
        default:
            return [
                "Identify the key concepts involved",
                "Think about similar problems you've solved",
                "Consider the context and requirements"
            ]
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
}

// MARK: - Supporting Views

struct StepCard: View {
    let step: String
    let stepNumber: Int
    let isRevealed: Bool
    let isSelected: Bool
    let totalSteps: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Step indicator
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Text("\(stepNumber)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("Step \(stepNumber) of \(totalSteps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(180))
                    }
                }
                
                if isRevealed {
                    Text(step)
                        .font(.body)
                        .foregroundColor(.primary)
                        .opacity(isRevealed ? 1 : 0)
                        .scaleEffect(isRevealed ? 1 : 0.8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(ConditionalLiquidGlass(
                style: isSelected ? .regular : .thin,
                luminosity: isSelected ? 1.2 : 0.8,
                refractionIntensity: isSelected ? 1.5 : 1.0
            ))
            .cornerRadius(16)
            .scaleEffect(isRevealed ? 1 : 0.95)
            .opacity(isRevealed ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FinalAnswerCard: View {
    let answer: String
    @State private var glowAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Final Answer")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Text(answer)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .modifier(ConditionalLiquidGlass(style: .regular, luminosity: 1.5))
                .cornerRadius(16)
                .shadow(
                    color: Color.green.opacity(glowAnimation ? 0.4 : 0.2),
                    radius: glowAnimation ? 20 : 10,
                    x: 0,
                    y: 5
                )
        }
        .padding()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                glowAnimation = true
            }
        }
    }
}

struct SubjectBadge: View {
    let subject: Subject
    
    var body: some View {
        Label(subject.rawValue, systemImage: subject.icon)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(subject.color)
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(difficulty.color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct TimeBadge: View {
    let date: Date
    
    var body: some View {
        Text(date, style: .relative)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct HintProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 6) {
            if total > 0 {
                ForEach(1...total, id: \.self) { index in
                    Circle()
                        .fill(index <= current ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Conditional Liquid Glass Modifier

struct ConditionalLiquidGlass: ViewModifier {
    enum Style {
        case ultraThin
        case thin
        case regular
        case thick
        case frosted
    }
    
    let style: Style
    let luminosity: Double
    let refractionIntensity: Double
    
    init(style: Style, luminosity: Double = 1.0, refractionIntensity: Double = 1.0) {
        self.style = style
        self.luminosity = luminosity
        self.refractionIntensity = refractionIntensity
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .liquidGlass(
                    style: liquidGlassStyle,
                    luminosity: luminosity,
                    refractionIntensity: refractionIntensity
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: [Color.white.opacity(opacity), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
    }
    
    @available(iOS 18.0, *)
    private var liquidGlassStyle: LiquidGlassMaterial.GlassStyle {
        switch style {
        case .ultraThin: return .ultraThin
        case .thin: return .thin
        case .regular: return .regular
        case .thick: return .thick
        case .frosted: return .frosted
        }
    }
    
    private var opacity: Double {
        switch style {
        case .ultraThin: return 0.05 * luminosity
        case .thin: return 0.1 * luminosity
        case .regular: return 0.15 * luminosity
        case .thick: return 0.2 * luminosity
        case .frosted: return 0.25 * luminosity
        }
    }
}