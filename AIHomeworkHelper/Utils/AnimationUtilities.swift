import SwiftUI

/// Advanced animation utilities for iOS 17+
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
}