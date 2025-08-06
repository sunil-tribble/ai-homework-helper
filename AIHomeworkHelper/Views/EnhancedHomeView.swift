import SwiftUI
import RealityKit
import CoreMotion

// MARK: - Enhanced Home View with Apple 2025 Liquid Glass

@available(iOS 18.0, *)
struct EnhancedHomeView: View {
    @StateObject private var performanceMetrics = PerformanceMetricsEngine.shared
    @StateObject private var environmentalAwareness = EnvironmentalAwareness.shared
    @StateObject private var hapticManager = HapticManager.shared
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedFeature: HomeFeature?
    @State private var glassTransition = false
    @State private var currentGlassStyle: MaterialXGlass.GlassStyle = .neural
    @State private var parallaxEnabled = true
    
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                ScrollView {
                VStack(spacing: 24) {
                    // Adaptive Glass Header
                    AdaptiveGlassHeader()
                        .materialXGlass(
                            style: currentGlassStyle,
                            luminosity: 1.2,
                            refractionIntensity: 1.5
                        )
                        .realityBounce()
                    
                    // Quick Actions Grid
                    QuickActionsGrid(selectedFeature: $selectedFeature)
                        .liquidMorph(to: .roundedRectangle)
                    
                    // AI Study Assistant Card
                    AIAssistantCard()
                        .materialXGlass(
                            style: .organic,
                            luminosity: 0.9,
                            environmentalContext: .automatic
                        )
                        .physicsAnimation()
                    
                    // Progress Dashboard with Neural Visualization
                    NeuralProgressDashboard()
                        .materialXGlass(
                            style: .neural,
                            luminosity: 1.0,
                            refractionIntensity: 1.2
                        )
                    
                    // Quantum Study Recommendations
                    QuantumRecommendations()
                        .materialXGlass(
                            style: .quantum,
                            luminosity: 0.8
                        )
                }
                .padding()
            }
            .onAppear {
                startEnvironmentalMonitoring()
            }
            .onChange(of: environmentalAwareness.emotionalState) { _, newState in
                adaptGlassStyle(for: newState)
            }
        } else {
            // Fallback for iOS versions before 18.0
            ScrollView {
                VStack(spacing: 24) {
                    Text("Enhanced features require iOS 18.0 or later")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        }
    }
    
    private func startEnvironmentalMonitoring() {
        Task {
            await environmentalAwareness.startMonitoring()
        }
    }
    
    private func adaptGlassStyle(for state: EmotionalState) {
        withAnimation(.emotionalSpring(state)) {
            switch state.mood {
            case .happy:
                currentGlassStyle = .liquid
            case .focused:
                currentGlassStyle = .crystalline
            case .stressed:
                currentGlassStyle = .organic
            case .neutral:
                currentGlassStyle = .neural
            }
        }
        
        // Haptic response to mood change
        hapticManager.playMaterialTransition(from: currentGlassStyle.stringValue, to: currentGlassStyle.stringValue)
    }
}

// MARK: - Adaptive Glass Header

@available(iOS 18.0, *)
struct AdaptiveGlassHeader: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var depthEngine = AppleDepthEngine.shared
    @State private var greetingScale: CGFloat = 1.0
    @State private var wavePhase: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Dynamic greeting with depth-aware text
            Text(dynamicGreeting)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(greetingScale)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            
            // Liquid progress indicator
            LiquidProgressBar(
                progress: Double(userManager.dailySolvesUsed) / Double(userManager.dailyGoal),
                wavePhase: wavePhase
            )
            .frame(height: 60)
            
            // Emotional status indicator
            EmotionalStatusPill()
        }
        .padding(32)
        .onAppear {
            animateGreeting()
            startWaveAnimation()
        }
    }
    
    private var dynamicGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userManager.username.isEmpty ? "Scholar" : userManager.username
        
        switch hour {
        case 0..<6:
            return "Night owl mode, \(name) 🦉"
        case 6..<12:
            return "Rise and solve, \(name) ☀️"
        case 12..<17:
            return "Crushing it, \(name) 💪"
        case 17..<22:
            return "Evening genius, \(name) ✨"
        default:
            return "Late night grind, \(name) 🌙"
        }
    }
    
    private func animateGreeting() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            greetingScale = 1.1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            greetingScale = 1.0
        }
    }
    
    private func startWaveAnimation() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            wavePhase = 2 * .pi
        }
    }
}

// MARK: - Liquid Progress Bar

@available(iOS 18.0, *)
struct LiquidProgressBar: View {
    let progress: Double
    let wavePhase: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background glass
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Liquid fill
                LiquidFill(
                    progress: progress,
                    wavePhase: wavePhase,
                    size: geometry.size
                )
                .mask(RoundedRectangle(cornerRadius: 30))
                
                // Progress text
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Daily Goal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Liquid Fill Shape

struct LiquidFill: View {
    let progress: Double
    let wavePhase: Double
    let size: CGSize
    
    var body: some View {
        Canvas { context, _ in
            // Ensure valid size
            guard size.width > 0 && size.height > 0 else { return }
            
            var path = Path()
            
            let fillHeight = size.height * (1 - progress)
            let waveAmplitude = 10.0
            
            path.move(to: CGPoint(x: 0, y: size.height))
            
            // Create wave path
            for x in stride(from: 0, through: size.width, by: 2) {
                let relativeX = x / size.width
                let sine = sin((relativeX * Double.pi * 4) + wavePhase)
                let y = fillHeight + sine * waveAmplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            
            // Fill with gradient
            let gradient = Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.6),
                Color.pink.opacity(0.4)
            ])
            
            context.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: fillHeight),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
        }
    }
}

// MARK: - Emotional Status Pill

@available(iOS 18.0, *)
struct EmotionalStatusPill: View {
    @StateObject private var awareness = EnvironmentalAwareness.shared
    @State private var isExpanded = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Mood indicator
            Circle()
                .fill(moodColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .blur(radius: 2)
                )
            
            Text(moodText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            if isExpanded {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [moodColor.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isExpanded ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
            HapticManager.shared.impact(.light)
        }
    }
    
    private var moodColor: Color {
        switch awareness.emotionalState.mood {
        case .happy: return .green
        case .focused: return .blue
        case .stressed: return .orange
        case .neutral: return .gray
        }
    }
    
    private var moodText: String {
        switch awareness.emotionalState.mood {
        case .happy: return "Feeling Great"
        case .focused: return "In The Zone"
        case .stressed: return "Take a Break"
        case .neutral: return "Ready to Learn"
        }
    }
}

// MARK: - Quick Actions Grid

@available(iOS 18.0, *)
struct QuickActionsGrid: View {
    @Binding var selectedFeature: HomeFeature?
    @State private var hoveredFeature: HomeFeature?
    
    let features: [HomeFeature] = [
        HomeFeature(
            id: "scan",
            title: "Scan Problem",
            icon: "camera.viewfinder",
            color: .blue,
            glassStyle: .liquid
        ),
        HomeFeature(
            id: "history",
            title: "Recent Solutions",
            icon: "clock.arrow.circlepath",
            color: .purple,
            glassStyle: .crystalline
        ),
        HomeFeature(
            id: "practice",
            title: "Practice Mode",
            icon: "brain.head.profile",
            color: .green,
            glassStyle: .organic
        ),
        HomeFeature(
            id: "compete",
            title: "Challenges",
            icon: "trophy.fill",
            color: .orange,
            glassStyle: .quantum
        )
    ]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(features) { feature in
                QuickActionCard(
                    feature: feature,
                    isHovered: hoveredFeature == feature,
                    onTap: {
                        selectedFeature = feature
                        HapticManager.shared.playOrganicTap(style: feature.glassStyle.stringValue)
                    }
                )
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        hoveredFeature = hovering ? feature : nil
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Card

@available(iOS 18.0, *)
struct QuickActionCard: View {
    let feature: HomeFeature
    let isHovered: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                feature.color.opacity(0.3),
                                feature.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .blur(radius: isHovered ? 20 : 10)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.1 : 1.0))
            }
            
            Text(feature.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .materialXGlass(
                    style: feature.glassStyle,
                    luminosity: isHovered ? 1.2 : 0.8,
                    refractionIntensity: 1.0
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Supporting Types

@available(iOS 18.0, *)
struct HomeFeature: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let glassStyle: MaterialXGlass.GlassStyle
}

// MARK: - AI Assistant Card

@available(iOS 18.0, *)
struct AIAssistantCard: View {
    @State private var aiResponse = ""
    @State private var isThinking = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse, value: pulseAnimation)
                
                Text("AI Study Assistant")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isThinking {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
            }
            
            Text("I'm here to help you understand complex problems and guide your learning journey.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            HStack {
                Text("Ask me anything")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Neural Progress Dashboard

@available(iOS 18.0, *)
struct NeuralProgressDashboard: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedMetric: ProgressMetric = .accuracy
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Learning Analytics")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                MetricPicker(selection: $selectedMetric)
            }
            
            // Neural visualization of progress
            NeuralProgressVisualization(
                metric: selectedMetric,
                data: userManager.weeklyProgress.map { $0 ? 1.0 : 0.0 }
            )
            .frame(height: 200)
            .interactiveParallax(depth: 1.2, faceTracking: true)
        }
        .padding(24)
    }
}

// MARK: - Quantum Recommendations

@available(iOS 18.0, *)
struct QuantumRecommendations: View {
    @State private var recommendations: [StudyRecommendation] = []
    @State private var quantumState: QuantumState = .superposition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quantum Study Paths")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                QuantumStateIndicator(state: $quantumState)
            }
            
            ForEach(recommendations) { recommendation in
                QuantumRecommendationCard(recommendation: recommendation)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(24)
        .onAppear {
            generateQuantumRecommendations()
        }
        .onChange(of: quantumState) { _, _ in
            HapticManager.shared.playQuantumCollapse()
            generateQuantumRecommendations()
        }
    }
    
    private func generateQuantumRecommendations() {
        // Simulate quantum recommendations
        recommendations = [
            StudyRecommendation(
                id: UUID().uuidString,
                title: "Advanced Calculus",
                probability: 0.87,
                icon: "function"
            ),
            StudyRecommendation(
                id: UUID().uuidString,
                title: "Linear Algebra",
                probability: 0.72,
                icon: "square.grid.3x3"
            )
        ]
    }
}

// MARK: - Supporting Components

enum ProgressMetric: String, CaseIterable {
    case accuracy = "Accuracy"
    case speed = "Speed"
    case mastery = "Mastery"
}

struct MetricPicker: View {
    @Binding var selection: ProgressMetric
    
    var body: some View {
        Menu {
            ForEach(ProgressMetric.allCases, id: \.self) { metric in
                Button(metric.rawValue) {
                    selection = metric
                }
            }
        } label: {
            Label(selection.rawValue, systemImage: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

@available(iOS 18.0, *)
struct NeuralProgressVisualization: View {
    let metric: ProgressMetric
    let data: [Double]
    
    var body: some View {
        // Placeholder for complex neural visualization
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                Text("Neural Network Visualization")
                    .foregroundColor(.white.opacity(0.5))
            )
    }
}

enum QuantumState {
    case superposition
    case entangled
    case collapsed
}

struct QuantumStateIndicator: View {
    @Binding var state: QuantumState
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach([QuantumState.superposition, .entangled, .collapsed], id: \.self) { quantumState in
                Circle()
                    .fill(state == quantumState ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        state = quantumState
                    }
            }
        }
        .padding(8)
        .background(Capsule().fill(.ultraThinMaterial))
    }
}

struct StudyRecommendation: Identifiable {
    let id: String
    let title: String
    let probability: Double
    let icon: String
}

struct QuantumRecommendationCard: View {
    let recommendation: StudyRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: recommendation.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(Int(recommendation.probability * 100))% probability")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - MaterialXGlass.GlassStyle Extension

@available(iOS 18.0, *)
extension MaterialXGlass.GlassStyle {
    var stringValue: String {
        switch self {
        case .ultraThin: return "ultraThin"
        case .thin: return "thin"
        case .regular: return "regular"
        case .thick: return "thick"
        case .frosted: return "frosted"
        case .liquid: return "liquid"
        case .crystalline: return "crystalline"
        case .organic: return "organic"
        case .quantum: return "quantum"
        case .neural: return "neural"
        }
    }
}

// MARK: - Preview Provider

@available(iOS 18.0, *)
struct EnhancedHomeView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedHomeView()
            .environmentObject(UserManager())
    }
}