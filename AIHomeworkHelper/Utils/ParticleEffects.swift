import SwiftUI

/// Reusable particle effects for magical animations
struct ParticleSystem: View {
    let particleCount: Int
    let duration: Double
    let particleSize: CGFloat
    let colors: [Color]
    let spread: CGFloat
    let emissionShape: EmissionShape
    
    @State private var particles: [Particle] = []
    @State private var animationTrigger = false
    
    enum EmissionShape {
        case point
        case circle(radius: CGFloat)
        case rectangle(width: CGFloat, height: CGFloat)
    }
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var color: Color
        var size: CGFloat
        var opacity: Double = 1.0
        var rotation: Double = 0
        var scale: CGFloat = 1.0
    }
    
    init(
        particleCount: Int = 20,
        duration: Double = 2.0,
        particleSize: CGFloat = 8,
        colors: [Color] = [.yellow, .orange, .red],
        spread: CGFloat = 100,
        emissionShape: EmissionShape = .point
    ) {
        self.particleCount = particleCount
        self.duration = duration
        self.particleSize = particleSize
        self.colors = colors
        self.spread = spread
        self.emissionShape = emissionShape
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size * particle.scale, height: particle.size * particle.scale)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .blur(radius: particle.opacity < 0.5 ? 2 : 0)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
        .onChange(of: animationTrigger) { _, _ in
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            let startPosition = getEmissionPosition()
            let angle = Double.random(in: 0...(2 * .pi))
            let minSpeed: CGFloat = min(50, spread)
            let maxSpeed: CGFloat = max(50, spread)
            let speed = CGFloat.random(in: minSpeed...maxSpeed)
            
            let minSize = max(1, particleSize * 0.5)
            let maxSize = max(minSize, particleSize * 1.5)
            
            return Particle(
                position: startPosition,
                velocity: CGVector(
                    dx: Darwin.cos(angle) * speed,
                    dy: Darwin.sin(angle) * speed
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: minSize...maxSize),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func getEmissionPosition() -> CGPoint {
        switch emissionShape {
        case .point:
            return .zero
        case .circle(let radius):
            let angle = Double.random(in: 0...(2 * .pi))
            let maxRadius = max(0, radius)
            let r = CGFloat.random(in: 0...maxRadius)
            return CGPoint(
                x: Darwin.cos(angle) * r,
                y: Darwin.sin(angle) * r
            )
        case .rectangle(let width, let height):
            let halfWidth = abs(width) / 2
            let halfHeight = abs(height) / 2
            return CGPoint(
                x: CGFloat.random(in: -halfWidth...halfWidth),
                y: CGFloat.random(in: -halfHeight...halfHeight)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: duration)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.dx
                particles[i].position.y += particles[i].velocity.dy
                particles[i].opacity = 0
                particles[i].scale = CGFloat.random(in: 0.5...2.0)
                particles[i].rotation += Double.random(in: -180...180)
            }
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            particles.removeAll()
        }
    }
    
    func trigger() {
        animationTrigger.toggle()
    }
}

/// Confetti burst effect
struct ConfettiBurst: View {
    let trigger: Bool
    
    var body: some View {
        ZStack {
            if trigger {
                ParticleSystem(
                    particleCount: 30,
                    duration: 3.0,
                    particleSize: 12,
                    colors: [.red, .yellow, .green, .blue, .purple, .orange, .pink],
                    spread: 200,
                    emissionShape: .circle(radius: 50)
                )
            }
        }
    }
}

/// Star burst effect for achievements
struct StarBurst: View {
    @State private var animate = false
    let size: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                StarBurstRay(
                    index: index,
                    size: size,
                    color: color,
                    animate: animate
                )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

/// Individual star burst ray
struct StarBurstRay: View {
    let index: Int
    let size: CGFloat
    let color: Color
    let animate: Bool
    
    var body: some View {
        ParticleStarShape(points: 4, smoothness: 0.3)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.3)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(animate ? 1.5 : 0.1)
            .opacity(animate ? 0 : 1)
            .rotationEffect(.degrees(Double(index) * 45))
            .animation(
                .easeOut(duration: 1.0)
                    .delay(Double(index) * 0.1),
                value: animate
            )
    }
}

/// Custom star shape for particles
struct ParticleStarShape: Shape {
    let points: Int
    let smoothness: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        let angleIncrement = .pi * 2 / Double(points * 2)
        
        var path = Path()
        
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleIncrement - .pi / 2
            let x = center.x + CGFloat(Darwin.cos(angle)) * radius
            let y = center.y + CGFloat(Darwin.sin(angle)) * radius
            
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

/// Ripple effect for button presses
struct RippleEffect: ViewModifier {
    @State private var ripples: [Ripple] = []
    
    struct Ripple: Identifiable {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 0.1
        var opacity: Double = 0.8
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(ripples) { ripple in
                        Circle()
                            .fill(Color.white.opacity(ripple.opacity))
                            .frame(width: 100, height: 100)
                            .scaleEffect(ripple.scale)
                            .position(ripple.position)
                            .allowsHitTesting(false)
                    }
                }
            )
            .onTapGesture { location in
                addRipple(at: location)
            }
    }
    
    private func addRipple(at location: CGPoint) {
        let ripple = Ripple(position: location)
        ripples.append(ripple)
        
        withAnimation(.easeOut(duration: 0.6)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].scale = 3.0
                ripples[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

extension View {
    func rippleEffect() -> some View {
        modifier(RippleEffect())
    }
}

/// Firework effect for celebrations
struct FireworkEffect: View {
    @State private var expand = false
    @State private var opacity: Double = 1.0
    let particleCount = 12
    let colors: [Color] = [.red, .yellow, .orange, .pink, .purple, .blue]
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .white)
                    .frame(width: 8, height: 8)
                    .offset(x: expand ? Darwin.cos(CGFloat(index) * 2 * .pi / CGFloat(particleCount)) * 80 : 0,
                           y: expand ? Darwin.sin(CGFloat(index) * 2 * .pi / CGFloat(particleCount)) * 80 : 0)
                    .opacity(opacity)
                    .blur(radius: expand ? 2 : 0)
                    .scaleEffect(expand ? 0.5 : 1.5)
            }
            
            // Center burst
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.yellow.opacity(0.5), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: expand ? 100 : 20, height: expand ? 100 : 20)
                .opacity(expand ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                expand = true
                opacity = 0
            }
        }
    }
}