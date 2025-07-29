import SwiftUI
import CoreMotion

// MARK: - Liquid Glass Design System
/// The Liquid Glass philosophy: Every interface element exists in four dimensions - width, height, depth, and duration

// MARK: - Glass Material System
struct LiquidGlassMaterial: ViewModifier {
    let style: GlassStyle
    let luminosity: Double
    let refractionIntensity: Double
    @State private var motionX: Double = 0
    @State private var motionY: Double = 0
    @StateObject private var motionManager = MotionManager.shared
    
    enum GlassStyle {
        case ultraThin      // For overlays and hints
        case thin           // For cards and buttons
        case regular        // For primary containers
        case thick          // For modals and sheets
        case frosted        // For backgrounds
    }
    
    private var blurRadius: Double {
        switch style {
        case .ultraThin: return 3
        case .thin: return 8
        case .regular: return 15
        case .thick: return 25
        case .frosted: return 40
        }
    }
    
    private var materialOpacity: Double {
        switch style {
        case .ultraThin: return 0.3
        case .thin: return 0.5
        case .regular: return 0.7
        case .thick: return 0.85
        case .frosted: return 0.95
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(materialOpacity)
                    
                    // Refraction layer - responds to device motion
                    LinearGradient(
                        colors: [
                            Color.white.opacity(luminosity * 0.3 + motionX * 0.1),
                            Color.clear,
                            Color.white.opacity(luminosity * 0.1 + motionY * 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.overlay)
                    
                    // Edge lighting
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6 * luminosity),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                    
                    // Inner shadow for depth
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 1)
                }
            )
            .overlay(
                // Specular highlight
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(luminosity * 0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.3
                            )
                        )
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(
                            x: -geometry.size.width * 0.3 + motionX * 20,
                            y: -geometry.size.height * 0.3 + motionY * 20
                        )
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
            )
            .onReceive(motionManager.$motion) { motion in
                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8)) {
                    motionX = motion.x * refractionIntensity
                    motionY = motion.y * refractionIntensity
                }
            }
    }
}

// MARK: - Morphing Glass Container
struct MorphingGlassContainer<Content: View>: View {
    let content: Content
    @State private var morphPhase: CGFloat = 0
    @State private var isPressed = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                MorphingGlass(phase: morphPhase, isPressed: isPressed)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .onTapGesture { }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = pressing
                    }
                },
                perform: { }
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    morphPhase = 1
                }
            }
    }
}

private struct MorphingGlass: View {
    let phase: CGFloat
    let isPressed: Bool
    
    var body: some View {
        ZStack {
            // Morphing base
            RoundedRectangle(cornerRadius: 16 + phase * 4)
                .fill(.ultraThinMaterial)
            
            // Dynamic reflection
            Canvas { context, size in
                let gradient = Gradient(colors: [
                    .white.opacity(0.3),
                    .white.opacity(0.1),
                    .clear
                ])
                
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width, y: 0),
                        control: CGPoint(x: size.width / 2, y: -20 * phase)
                    )
                    path.addLine(to: CGPoint(x: size.width, y: size.height * 0.6))
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: size.height * 0.4),
                        control: CGPoint(x: size.width / 2, y: size.height * 0.5 + 20 * phase)
                    )
                    path.closeSubpath()
                }
                
                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
            }
            .blendMode(.overlay)
            
            // Pressure response
            if isPressed {
                RoundedRectangle(cornerRadius: 16 + phase * 4)
                    .fill(
                        RadialGradient(
                            colors: [Color.black.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
            }
        }
    }
}

// MARK: - Liquid Transition
struct LiquidTransition: ViewModifier {
    let isVisible: Bool
    @State private var ripplePhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    if isVisible {
                        Circle()
                            .frame(
                                width: geometry.size.width * 2 * ripplePhase,
                                height: geometry.size.height * 2 * ripplePhase
                            )
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                    }
                }
            )
            .onChange(of: isVisible) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        ripplePhase = 1.5
                    }
                } else {
                    ripplePhase = 0
                }
            }
    }
}

// MARK: - Depth Card System
struct DepthCard<Content: View>: View {
    let depth: DepthLevel
    let content: Content
    @State private var isHovered = false
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    
    enum DepthLevel: CGFloat {
        case surface = 0
        case raised = 1
        case floating = 2
        case elevated = 3
        
        var shadowRadius: CGFloat {
            rawValue * 8 + 4
        }
        
        var shadowY: CGFloat {
            rawValue * 4 + 2
        }
        
        var shadowOpacity: Double {
            0.1 + (rawValue * 0.05)
        }
    }
    
    init(depth: DepthLevel = .raised, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(depth.shadowOpacity),
                radius: depth.shadowRadius,
                x: dragOffset.width * 0.1,
                y: depth.shadowY + dragOffset.height * 0.1
            )
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.05 : (isHovered ? 1.02 : 1.0))
            .rotation3DEffect(
                .degrees(Double(dragOffset.width) * 0.05),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-dragOffset.height) * 0.05),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Liquid Button
struct LiquidButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let style: ButtonStyle
    
    @State private var isPressed = false
    @State private var ripples: [RippleData] = []
    @State private var glowIntensity: Double = 0
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        
        var baseColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray
            case .ghost: return .clear
            }
        }
    }
    
    struct RippleData: Identifiable {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 0
        var opacity: Double = 0.6
    }
    
    init(
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.style = style
        self.label = label()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base layer
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.baseColor.opacity(style == .ghost ? 0 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .opacity(style == .ghost ? 0 : 0.8)
                    )
                
                // Ripple effects
                ForEach(ripples) { ripple in
                    Circle()
                        .fill(Color.white.opacity(ripple.opacity))
                        .frame(width: 200, height: 200)
                        .scaleEffect(ripple.scale)
                        .position(ripple.position)
                        .allowsHitTesting(false)
                }
                
                // Glow effect
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                style.baseColor.opacity(glowIntensity),
                                style.baseColor.opacity(glowIntensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 2)
                
                // Label
                label
                    .foregroundColor(style == .ghost ? .primary : .white)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture(coordinateSpace: .local) { location in
                // Haptic feedback
                HapticManager.shared.impact(.medium)
                
                // Create ripple
                let ripple = RippleData(position: location)
                ripples.append(ripple)
                
                // Animate ripple
                withAnimation(.easeOut(duration: 0.6)) {
                    if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                        ripples[index].scale = 3
                        ripples[index].opacity = 0
                    }
                }
                
                // Glow animation
                withAnimation(.easeIn(duration: 0.1)) {
                    glowIntensity = 0.8
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    glowIntensity = 0
                }
                
                // Clean up ripples
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    ripples.removeAll { $0.id == ripple.id }
                }
                
                // Execute action
                action()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.easeOut(duration: 0.1)) {
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
        .frame(height: 56)
    }
}

// MARK: - Motion Manager
class MotionManager: ObservableObject {
    static let shared = MotionManager()
    
    @Published var motion: (x: Double, y: Double) = (0, 0)
    private var motionManager = CMMotionManager()
    
    private init() {
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else { return }
            
            self?.motion = (
                x: motion.gravity.x,
                y: motion.gravity.y
            )
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(
        style: LiquidGlassMaterial.GlassStyle = .regular,
        luminosity: Double = 1.0,
        refractionIntensity: Double = 1.0
    ) -> some View {
        modifier(LiquidGlassMaterial(
            style: style,
            luminosity: luminosity,
            refractionIntensity: refractionIntensity
        ))
    }
    
    func liquidTransition(isVisible: Bool) -> some View {
        modifier(LiquidTransition(isVisible: isVisible))
    }
}