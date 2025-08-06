import SwiftUI
import UIKit
import AVFoundation
import CoreHaptics

// MARK: - Celebration Engine
/// Creates contextual, shareable celebration moments that adapt to achievement significance
class CelebrationEngine: ObservableObject {
    static let shared = CelebrationEngine()
    
    @Published var isAnimating = false
    @Published var currentCelebration: CelebrationStyle?
    @Published var shareableFrameCapture: UIImage?
    
    @MainActor private let hapticManager = HapticManager.shared
    @MainActor private let soundManager = SoundManager.shared
    private var celebrationQueue: [CelebrationEvent] = []
    
    enum CelebrationStyle {
        case subtleSuccess      // Small wins
        case levelUp           // Progress milestones
        case majorAchievement  // Big accomplishments
        case epicWin           // Viral-worthy moments
        case perfectScore      // Flawless execution
        case streakContinued   // Consistency rewards
        case firstTime         // New user achievements
        
        var duration: Double {
            switch self {
            case .subtleSuccess: return 1.5
            case .levelUp: return 2.5
            case .majorAchievement: return 3.5
            case .epicWin: return 5.0
            case .perfectScore: return 4.0
            case .streakContinued: return 2.0
            case .firstTime: return 3.0
            }
        }
        
        var hapticPattern: String {
            switch self {
            case .subtleSuccess: return "success_light"
            case .levelUp: return "level_up_cascade"
            case .majorAchievement: return "achievement_symphony"
            case .epicWin: return "epic_crescendo"
            case .perfectScore: return "perfect_harmony"
            case .streakContinued: return "streak_pulse"
            case .firstTime: return "discovery_bloom"
            }
        }
    }
    
    struct CelebrationEvent {
        let id = UUID()
        let style: CelebrationStyle
        let context: CelebrationContext
        let timestamp = Date()
    }
    
    struct CelebrationContext {
        let achievementName: String
        let score: Int?
        let streakCount: Int?
        let isPersonalBest: Bool
        let category: String
        
        var significanceScore: Double {
            var score = 0.0
            if isPersonalBest { score += 0.4 }
            if let streak = streakCount, streak > 5 { score += 0.3 }
            if let points = self.score, points > 90 { score += 0.3 }
            return min(score, 1.0)
        }
    }
    
    // MARK: - Trigger Celebrations
    
    func celebrate(_ style: CelebrationStyle, context: CelebrationContext) {
        let event = CelebrationEvent(style: style, context: context)
        celebrationQueue.append(event)
        
        if !isAnimating {
            processNextCelebration()
        }
    }
    
    private func processNextCelebration() {
        guard let event = celebrationQueue.first else {
            isAnimating = false
            return
        }
        
        celebrationQueue.removeFirst()
        isAnimating = true
        currentCelebration = event.style
        
        // Trigger multi-sensory celebration
        Task {
            await performCelebration(event)
        }
    }
    
    @MainActor
    private func performCelebration(_ event: CelebrationEvent) async {
        // Haptic symphony
        hapticManager.playOrganicTap(style: "celebration")
        
        // Capture shareable moment at peak
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(event.style.duration * 0.6 * 1_000_000_000))
            captureShareableFrame()
        }
        
        // Complete celebration
        try? await Task.sleep(nanoseconds: UInt64(event.style.duration * 1_000_000_000))
        
        currentCelebration = nil
        processNextCelebration()
    }
    
    private func captureShareableFrame() {
        // Capture current screen for sharing
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        shareableFrameCapture = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}

// MARK: - Celebration Views

struct SubtleSuccessAnimation: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Gentle pulse rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(scale * (1 + Double(index) * 0.2))
                    .opacity(opacity * (1 - Double(index) * 0.3))
            }
            
            // Central checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                rotation = 360
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                opacity = 0
            }
        }
    }
}

struct LevelUpAnimation: View {
    @State private var textScale: CGFloat = 0
    @State private var glowIntensity: Double = 0
    @State private var starRotations: [Double] = Array(repeating: 0, count: 5)
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            // Particle fountain
            if showParticles {
                ParticleSystem(
                    particleCount: 50,
                    duration: 2.0,
                    particleSize: 8,
                    colors: [.yellow, .orange, .red],
                    spread: 100,
                    emissionShape: .circle(radius: 100)
                )
            }
            
            // Animated stars
            ForEach(0..<5) { index in
                StarShape(points: 5, smoothness: 0.5)
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(starRotations[index]))
                    .offset(
                        x: cos(Double(index) * .pi / 2.5) * 80,
                        y: sin(Double(index) * .pi / 2.5) * 80
                    )
                    .scaleEffect(textScale)
            }
            
            // Level up text
            VStack(spacing: 0) {
                Text("LEVEL")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Text("UP!")
                    .font(.system(size: 40, weight: .black, design: .rounded))
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(textScale)
            .shadow(color: .orange.opacity(glowIntensity), radius: 20)
        }
        .onAppear {
            // Text and stars animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                textScale = 1.2
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                textScale = 1
            }
            
            // Glow pulse
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                glowIntensity = 1
            }
            
            // Star rotations
            for index in 0..<5 {
                withAnimation(.linear(duration: 2).delay(Double(index) * 0.1)) {
                    starRotations[index] = 360
                }
            }
            
            // Show particles
            showParticles = true
        }
    }
}

struct EpicWinAnimation: View {
    @State private var phase: CGFloat = 0
    @State private var explosionScale: CGFloat = 0
    @State private var lightBeams: [LightBeam] = []
    @State private var textOpacity: Double = 0
    @State private var crownScale: CGFloat = 0
    
    struct LightBeam: Identifiable {
        let id = UUID()
        let angle: Double
        let color: Color
        var length: CGFloat = 0
        var opacity: Double = 0
    }
    
    var body: some View {
        ZStack {
            // Radial light beams
            ForEach(lightBeams) { beam in
                LightBeamView(beam: beam, explosionScale: explosionScale)
            }
            
            // Explosion rings
            ForEach(0..<5) { index in
                ExplosionRing(
                    index: index,
                    explosionScale: explosionScale,
                    phase: phase
                )
            }
            
            // Trophy or crown
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(crownScale)
                .rotationEffect(.degrees(Foundation.sin(phase) * 10))
                .shadow(color: .yellow, radius: 30)
            
            // Epic win text
            Text("EPIC WIN!")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(textOpacity)
                .scaleEffect(1 + sin(phase * 2) * 0.1)
                .offset(y: 150)
                .shadow(color: .orange, radius: 20)
        }
        .onAppear {
            // Initialize light beams
            for i in 0..<12 {
                lightBeams.append(LightBeam(
                    angle: Double(i) * 30,
                    color: [.purple, .pink, .orange, .yellow].randomElement() ?? .purple
                ))
            }
            
            // Explosion animation
            withAnimation(.easeOut(duration: 0.8)) {
                explosionScale = 1.5
                
                // Animate light beams
                for index in lightBeams.indices {
                    lightBeams[index].length = 300
                    lightBeams[index].opacity = 0.8
                }
            }
            
            // Crown entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3)) {
                crownScale = 1
            }
            
            // Text reveal
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                textOpacity = 1
            }
            
            // Continuous rotation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
            
            // Fade out beams
            withAnimation(.easeOut(duration: 2).delay(2)) {
                for index in lightBeams.indices {
                    lightBeams[index].opacity = 0
                }
            }
        }
    }
}

// MARK: - Celebration Particle System
private class CelebrationParticleSystem {
    var particles: [Particle] = []
    
    struct Particle {
        var position: CGPoint
        var velocity: CGVector
        var color: Color
        var size: CGFloat
        var lifetime: Double
        var age: Double = 0
    }
    
    func emit(count: Int, from origin: CGPoint, color: Color) {
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 100...300)
            
            let particle = Particle(
                position: origin,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed - 200 // Upward bias
                ),
                color: color,
                size: CGFloat.random(in: 4...8),
                lifetime: Double.random(in: 1...2)
            )
            
            particles.append(particle)
        }
    }
    
    func update(at time: Date) {
        let deltaTime = 1.0 / 60.0
        
        particles = particles.compactMap { particle in
            var updated = particle
            
            // Update position
            updated.position.x += updated.velocity.dx * deltaTime
            updated.position.y += updated.velocity.dy * deltaTime
            
            // Apply gravity
            updated.velocity.dy += 300 * deltaTime
            
            // Update age
            updated.age += deltaTime
            
            // Remove old particles
            return updated.age < updated.lifetime ? updated : nil
        }
    }
    
    func draw(in context: GraphicsContext, size: CGSize) {
        for particle in particles {
            let opacity = 1.0 - (particle.age / particle.lifetime)
            
            context.fill(
                Circle().path(in: CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )),
                with: .color(particle.color.opacity(opacity))
            )
        }
    }
}

// MARK: - Explosion Ring View
struct ExplosionRing: View {
    let index: Int
    let explosionScale: CGFloat
    let phase: CGFloat
    
    var body: some View {
        let scaleFactor = explosionScale * (1 + Double(index) * 0.3)
        let opacityValue = 1 - Double(index) * 0.2
        let rotationDegrees = phase * Double(index + 1) * 30
        
        Circle()
            .stroke(
                AngularGradient(
                    colors: [.purple, .pink, .orange, .yellow, .purple],
                    center: .center
                ),
                lineWidth: 3
            )
            .scaleEffect(scaleFactor)
            .opacity(opacityValue)
            .rotationEffect(.degrees(rotationDegrees))
    }
}

// MARK: - Light Beam View
struct LightBeamView: View {
    let beam: EpicWinAnimation.LightBeam
    let explosionScale: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [beam.color.opacity(beam.opacity), beam.color.opacity(0)],
                    startPoint: .center,
                    endPoint: .trailing
                )
            )
            .frame(width: beam.length, height: 20)
            .rotationEffect(.degrees(beam.angle))
            .scaleEffect(x: 1, y: explosionScale, anchor: .leading)
    }
}

// MARK: - Star Shape
struct StarShape: Shape {
    let points: Int
    let smoothness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        let angleIncrement = .pi * 2 / CGFloat(points * 2)
        
        var path = Path()
        
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(i) * angleIncrement - .pi / 2
            
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Celebration Container
struct CelebrationContainer<Content: View>: View {
    @ViewBuilder let content: Content
    @StateObject private var celebrationEngine = CelebrationEngine.shared
    
    var body: some View {
        ZStack {
            content
            
            if celebrationEngine.isAnimating {
                celebrationOverlay
                    .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        switch celebrationEngine.currentCelebration {
        case .subtleSuccess:
            SubtleSuccessAnimation()
        case .levelUp:
            LevelUpAnimation()
        case .epicWin:
            EpicWinAnimation()
        default:
            EmptyView()
        }
    }
}

// MARK: - View Extension
extension View {
    func celebrationEnabled() -> some View {
        CelebrationContainer { self }
    }
}

#Preview {
    VStack(spacing: 40) {
        Button("Subtle Success") {
            CelebrationEngine.shared.celebrate(
                .subtleSuccess,
                context: .init(
                    achievementName: "First Problem Solved",
                    score: 85,
                    streakCount: nil,
                    isPersonalBest: false,
                    category: "Math"
                )
            )
        }
        
        Button("Level Up") {
            CelebrationEngine.shared.celebrate(
                .levelUp,
                context: .init(
                    achievementName: "Bronze Badge Earned",
                    score: nil,
                    streakCount: 5,
                    isPersonalBest: true,
                    category: "Progress"
                )
            )
        }
        
        Button("Epic Win") {
            CelebrationEngine.shared.celebrate(
                .epicWin,
                context: .init(
                    achievementName: "Perfect Week",
                    score: 100,
                    streakCount: 7,
                    isPersonalBest: true,
                    category: "Streak"
                )
            )
        }
    }
    .padding()
    .celebrationEnabled()
}