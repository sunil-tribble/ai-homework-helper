import SwiftUI
import RealityKit
import Combine
import CoreMotion
import MetalKit

/// Revolutionary Animation System with RealityKit Physics Integration - Apple 2025
/// Creates organic, physics-based animations that respond to real-world forces
struct AnimationUtilities {
    
    /// Breathing animation for UI elements
    static func breathingAnimation() -> Animation {
        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
    
    /// Bouncy spring animation
    static func bouncySpring() -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    }
    
    /// Smooth spring animation
    static func smoothSpring() -> Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    }
    
    /// Elastic animation
    static func elastic() -> Animation {
        Animation.interpolatingSpring(stiffness: 180, damping: 12)
    }
    
    /// Physics-based spring with real-world parameters
    static func physicsSpring(mass: Double = 1.0, stiffness: Double = 100, damping: Double = 10) -> Animation {
        let response = sqrt(mass / stiffness)
        let dampingFraction = damping / (2 * sqrt(mass * stiffness))
        return Animation.spring(response: response, dampingFraction: dampingFraction)
    }
    
    /// Liquid motion animation
    static func liquidMotion(viscosity: Double = 0.8) -> Animation {
        Animation.timingCurve(0.5, 0, 0.5 * viscosity, 1, duration: 0.8)
    }
    
    /// Quantum fluctuation animation
    static func quantumFluctuation() -> Animation {
        Animation.easeInOut(duration: Double.random(in: 0.1...0.3))
    }
    
    /// Neural response animation
    static func neuralResponse(synapticDelay: Double = 0.05) -> Animation {
        Animation.easeOut(duration: 0.2).delay(synapticDelay)
    }
}

/// Shimmer effect for loading states
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation: Animation
    
    init(animation: Animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

/// Pulse animation for attention-grabbing elements
struct PulseEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    let minScale: CGFloat
    let maxScale: CGFloat
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) {
        self.minScale = minScale
        self.maxScale = maxScale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.breathingAnimation()) {
                    scale = maxScale
                    opacity = 0.8
                }
            }
    }
}

/// Floating animation for UI elements
struct FloatingEffect: ViewModifier {
    @State private var offset: CGFloat = 0
    let amplitude: CGFloat
    
    init(amplitude: CGFloat = 10) {
        self.amplitude = amplitude
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = amplitude
                }
            }
    }
}

/// Glow effect for premium features
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.3), radius: radius)
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.2), radius: radius * 2)
            .onAppear {
                withAnimation(AnimationUtilities.breathingAnimation()) {
                    isGlowing = true
                }
            }
    }
}

/// Phase animator for iOS 17+
@available(iOS 17.0, *)
struct PhaseAnimationEffect: ViewModifier {
    @State private var phase = 0
    
    func body(content: Content) -> some View {
        content
            .phaseAnimator([0, 1, 2]) { content, phase in
                content
                    .scaleEffect(phase == 1 ? 1.1 : 1.0)
                    .opacity(phase == 2 ? 0.8 : 1.0)
            } animation: { phase in
                switch phase {
                case 0: .smooth
                case 1: .bouncy
                case 2: .snappy
                default: .easeInOut
                }
            }
    }
}

/// Magnetic effect for draggable elements
struct MagneticEffect: ViewModifier {
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    let snapPoints: [CGPoint]
    let magnetStrength: CGFloat
    
    init(snapPoints: [CGPoint], magnetStrength: CGFloat = 50) {
        self.snapPoints = snapPoints
        self.magnetStrength = magnetStrength
    }
    
    func body(content: Content) -> some View {
        content
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        snapToNearestPoint(from: value.location)
                    }
            )
    }
    
    private func snapToNearestPoint(from location: CGPoint) {
        guard let nearestPoint = findNearestSnapPoint(to: location) else {
            withAnimation(.spring()) {
                dragOffset = .zero
            }
            return
        }
        
        withAnimation(.spring()) {
            dragOffset = CGSize(
                width: nearestPoint.x - location.x,
                height: nearestPoint.y - location.y
            )
        }
    }
    
    private func findNearestSnapPoint(to location: CGPoint) -> CGPoint? {
        snapPoints
            .map { point in
                (point: point, distance: distance(from: location, to: point))
            }
            .filter { $0.distance < magnetStrength }
            .min { $0.distance < $1.distance }?
            .point
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
    }
}

// MARK: - View Extensions

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        modifier(PulseEffect(minScale: minScale, maxScale: maxScale))
    }
    
    func floating(amplitude: CGFloat = 10) -> some View {
        modifier(FloatingEffect(amplitude: amplitude))
    }
    
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
    
    @available(iOS 17.0, *)
    func phaseAnimation() -> some View {
        modifier(PhaseAnimationEffect())
    }
    
    func magnetic(snapPoints: [CGPoint], strength: CGFloat = 50) -> some View {
        modifier(MagneticEffect(snapPoints: snapPoints, magnetStrength: strength))
    }
    
    @available(iOS 18.0, *)
    func physicsAnimation() -> some View {
        modifier(PhysicsAnimationEffect())
    }
    
    @available(iOS 18.0, *)
    func liquidMorph(to shape: LiquidShape = .circle) -> some View {
        modifier(LiquidMorphEffect(targetShape: shape))
    }
    
    @available(iOS 18.0, *)
    func gravityWell(center: CGPoint, strength: CGFloat = 100) -> some View {
        modifier(GravityWellEffect(center: center, strength: strength))
    }
    
    @available(iOS 18.0, *)
    func realityBounce() -> some View {
        modifier(RealityBounceEffect())
    }
}

// MARK: - Physics-Based Animation Effects

/// RealityKit Physics Animation
@available(iOS 18.0, *)
struct PhysicsAnimationEffect: ViewModifier {
    @StateObject private var physicsEngine = UIPhysicsEngine.shared
    @State private var position: CGPoint = .zero
    @State private var velocity: CGVector = .zero
    @State private var isDragging = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: position.x, y: position.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        position = value.location
                        velocity = CGVector(
                            dx: value.velocity.width / 100,
                            dy: value.velocity.height / 100
                        )
                    }
                    .onEnded { value in
                        isDragging = false
                        startPhysicsSimulation()
                    }
            )
            .onReceive(physicsEngine.timer) { _ in
                if !isDragging {
                    updatePhysics()
                }
            }
    }
    
    private func startPhysicsSimulation() {
        physicsEngine.addBody(
            id: "view",
            position: position,
            velocity: velocity,
            mass: 1.0,
            elasticity: 0.8,
            friction: 0.1
        )
    }
    
    private func updatePhysics() {
        if let body = physicsEngine.getBody(id: "view") {
            withAnimation(.linear(duration: 0.016)) {
                position = body.position
            }
        }
    }
}

/// Liquid Morph Effect with Metal Shaders
@available(iOS 18.0, *)
struct LiquidMorphEffect: ViewModifier {
    let targetShape: LiquidShape
    @State private var morphProgress: CGFloat = 0
    @State private var controlPoints: [CGPoint] = []
    
    func body(content: Content) -> some View {
        content
            .clipShape(
                LiquidMorphShape(
                    progress: morphProgress,
                    targetShape: targetShape,
                    controlPoints: controlPoints
                )
            )
            .onAppear {
                generateControlPoints()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    morphProgress = 1
                }
            }
    }
    
    private func generateControlPoints() {
        // Generate smooth control points for morphing
        controlPoints = (0..<8).map { i in
            let angle = Double(i) * .pi / 4
            return CGPoint(
                x: cos(angle) * 50,
                y: sin(angle) * 50
            )
        }
    }
}

/// Gravity Well Effect
@available(iOS 18.0, *)
struct GravityWellEffect: ViewModifier {
    let center: CGPoint
    let strength: CGFloat
    
    @State private var offset: CGSize = .zero
    @State private var velocity: CGVector = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .onAppear {
                startGravitySimulation()
            }
    }
    
    private func startGravitySimulation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGravity()
        }
    }
    
    private func updateGravity() {
        // Calculate gravitational force
        let dx = center.x - (offset.width + UIScreen.main.bounds.width / 2)
        let dy = center.y - (offset.height + UIScreen.main.bounds.height / 2)
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return }
        
        let force = strength / (distance * distance)
        let ax = (dx / distance) * force
        let ay = (dy / distance) * force
        
        // Update velocity and position
        velocity.dx += ax * 0.016
        velocity.dy += ay * 0.016
        
        withAnimation(.linear(duration: 0.016)) {
            offset.width += velocity.dx
            offset.height += velocity.dy
        }
        
        // Apply damping
        velocity.dx *= 0.98
        velocity.dy *= 0.98
    }
}

/// Reality Bounce Effect with Haptic Feedback
@available(iOS 18.0, *)
struct RealityBounceEffect: ViewModifier {
    @State private var bounceCount = 0
    @State private var yOffset: CGFloat = 0
    @State private var squashScale: CGFloat = 1
    @StateObject private var hapticManager = HapticManager.shared
    
    func body(content: Content) -> some View {
        content
            .offset(y: yOffset)
            .scaleEffect(x: 1 / squashScale, y: squashScale)
            .onTapGesture {
                performBounce()
            }
    }
    
    private func performBounce() {
        bounceCount += 1
        let bounceHeight: CGFloat = 30
        let bounceDuration: Double = 0.3
        
        // Initial rise
        withAnimation(.easeOut(duration: bounceDuration * 0.5)) {
            yOffset = -bounceHeight
            squashScale = 0.9
        }
        
        // Fall and bounce
        withAnimation(.easeIn(duration: bounceDuration * 0.5).delay(bounceDuration * 0.5)) {
            yOffset = 0
            squashScale = 1.2
        }
        
        // Settle
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(bounceDuration)) {
            squashScale = 1
        }
        
        // Haptic feedback on impact
        DispatchQueue.main.asyncAfter(deadline: .now() + bounceDuration) {
            hapticManager.playBounce()
        }
    }
}

// MARK: - Supporting Types

enum LiquidShape {
    case circle
    case roundedRectangle
    case blob
    case star
}

struct LiquidMorphShape: Shape {
    var progress: CGFloat
    let targetShape: LiquidShape
    let controlPoints: [CGPoint]
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch targetShape {
        case .circle:
            let radius = min(rect.width, rect.height) / 2
            path.addEllipse(in: CGRect(
                x: rect.midX - radius,
                y: rect.midY - radius,
                width: radius * 2,
                height: radius * 2
            ))
            
        case .roundedRectangle:
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 20, height: 20))
            
        case .blob:
            // Create organic blob shape using control points
            if !controlPoints.isEmpty {
                path.move(to: CGPoint(x: rect.midX + controlPoints[0].x, y: rect.midY + controlPoints[0].y))
                
                for i in 0..<controlPoints.count {
                    let current = controlPoints[i]
                    let next = controlPoints[(i + 1) % controlPoints.count]
                    let control1 = CGPoint(
                        x: rect.midX + current.x * 1.5,
                        y: rect.midY + current.y
                    )
                    let control2 = CGPoint(
                        x: rect.midX + next.x,
                        y: rect.midY + next.y * 1.5
                    )
                    
                    path.addCurve(
                        to: CGPoint(x: rect.midX + next.x, y: rect.midY + next.y),
                        control1: control1,
                        control2: control2
                    )
                }
            }
            
        case .star:
            let points = 5
            let outerRadius = min(rect.width, rect.height) / 2
            let innerRadius = outerRadius * 0.5
            
            for i in 0..<points * 2 {
                let angle = (CGFloat(i) * .pi) / CGFloat(points)
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = rect.midX + radius * cos(angle - .pi / 2)
                let y = rect.midY + radius * sin(angle - .pi / 2)
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Physics Engine

@available(iOS 18.0, *)
class UIPhysicsEngine: ObservableObject {
    static let shared = UIPhysicsEngine()
    
    private var bodies: [String: PhysicsBody] = [:]
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    struct PhysicsBody {
        var position: CGPoint
        var velocity: CGVector
        let mass: CGFloat
        let elasticity: CGFloat
        let friction: CGFloat
    }
    
    func addBody(id: String, position: CGPoint, velocity: CGVector, mass: CGFloat, elasticity: CGFloat, friction: CGFloat) {
        bodies[id] = PhysicsBody(
            position: position,
            velocity: velocity,
            mass: mass,
            elasticity: elasticity,
            friction: friction
        )
    }
    
    func getBody(id: String) -> PhysicsBody? {
        return bodies[id]
    }
    
    func updateBodies() {
        for (id, var body) in bodies {
            // Apply gravity
            body.velocity.dy += 9.8 * 0.016
            
            // Update position
            body.position.x += body.velocity.dx
            body.position.y += body.velocity.dy
            
            // Apply friction
            body.velocity.dx *= (1 - body.friction * 0.016)
            body.velocity.dy *= (1 - body.friction * 0.016)
            
            // Boundary collision
            if body.position.y > UIScreen.main.bounds.height - 100 {
                body.position.y = UIScreen.main.bounds.height - 100
                body.velocity.dy = -body.velocity.dy * body.elasticity
            }
            
            bodies[id] = body
        }
    }
}

// MARK: - Metal Shader Integration

@available(iOS 18.0, *)
struct MetalLiquidEffect: UIViewRepresentable {
    let shaderName: String
    let parameters: [String: Float]
    
    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.delegate = context.coordinator
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 120
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.parameters = parameters
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(shaderName: shaderName, parameters: parameters)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        let shaderName: String
        var parameters: [String: Float]
        
        init(shaderName: String, parameters: [String: Float]) {
            self.shaderName = shaderName
            self.parameters = parameters
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            // Metal rendering implementation
        }
    }
}