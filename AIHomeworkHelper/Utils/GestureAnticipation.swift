import SwiftUI
import UIKit
import Combine
import CoreHaptics

// MARK: - Gesture Anticipation Engine
/// Predicts user interactions and provides pre-touch feedback for a more responsive experience
class GestureAnticipationEngine: ObservableObject {
    static let shared = GestureAnticipationEngine()
    
    @Published var hoverLocation: CGPoint = .zero
    @Published var anticipationIntensity: Double = 0
    @Published var gestureVelocity: CGVector = .zero
    @Published var predictedTouchPoint: CGPoint?
    @Published var gestureConfidence: Double = 0
    
    private var touchPredictionModel = TouchPredictionModel()
    private var hoverTimer: Timer?
    private var velocityHistory: [CGVector] = []
    @MainActor private let hapticManager = HapticManager.shared
    
    private init() {
        setupGestureMonitoring()
    }
    
    private func setupGestureMonitoring() {
        // Monitor for hover states on supported devices
        // TODO: Implement proper pointer interaction handling
        // UIPointerInteraction doesn't have a pointerDidEnterRegion notification
    }
    
    @objc private func handlePointerInteraction(_ notification: Notification) {
        // Hover detection for iPad with trackpad/mouse
        DispatchQueue.main.async { [weak self] in
            self?.triggerAnticipationFeedback()
        }
    }
    
    // MARK: - Gesture Prediction
    
    func updateGestureTracking(location: CGPoint, velocity: CGVector) {
        hoverLocation = location
        gestureVelocity = velocity
        
        // Add to velocity history for prediction
        velocityHistory.append(velocity)
        if velocityHistory.count > 10 {
            velocityHistory.removeFirst()
        }
        
        // Calculate gesture confidence based on velocity consistency
        gestureConfidence = calculateGestureConfidence()
        
        // Predict touch point
        if gestureConfidence > 0.7 {
            predictedTouchPoint = predictTouchLocation()
            
            // Trigger anticipation feedback
            if anticipationIntensity < 0.8 {
                withAnimation(.easeIn(duration: 0.2)) {
                    anticipationIntensity = min(gestureConfidence, 0.8)
                }
            }
        }
    }
    
    private func calculateGestureConfidence() -> Double {
        guard velocityHistory.count >= 3 else { return 0 }
        
        // Calculate velocity consistency
        var totalDeviation = 0.0
        for i in 1..<velocityHistory.count {
            let prev = velocityHistory[i-1]
            let curr = velocityHistory[i]
            let deviation = sqrt(pow(curr.dx - prev.dx, 2) + pow(curr.dy - prev.dy, 2))
            totalDeviation += deviation
        }
        
        let avgDeviation = totalDeviation / Double(velocityHistory.count - 1)
        return max(0, 1.0 - (avgDeviation / 100.0))
    }
    
    private func predictTouchLocation() -> CGPoint {
        // Simple linear prediction based on velocity
        let avgVelocity = velocityHistory.reduce(CGVector.zero) { result, velocity in
            CGVector(dx: result.dx + velocity.dx / Double(velocityHistory.count),
                    dy: result.dy + velocity.dy / Double(velocityHistory.count))
        }
        
        // Predict 0.1 seconds into the future
        let predictedX = hoverLocation.x + avgVelocity.dx * 0.1
        let predictedY = hoverLocation.y + avgVelocity.dy * 0.1
        
        return CGPoint(x: predictedX, y: predictedY)
    }
    
    // MARK: - Anticipation Feedback
    
    @MainActor
    private func triggerAnticipationFeedback() {
        // Create subtle haptic that increases as user approaches
        hapticManager.playAnticipationPattern(intensity: anticipationIntensity)
    }
    
    func resetAnticipation() {
        withAnimation(.easeOut(duration: 0.3)) {
            anticipationIntensity = 0
            predictedTouchPoint = nil
            gestureConfidence = 0
        }
        velocityHistory.removeAll()
    }
}

// MARK: - Touch Prediction Model
private class TouchPredictionModel {
    // Simple ML-inspired model for touch prediction
    func predictGestureType(from velocityHistory: [CGVector]) -> GestureType {
        guard velocityHistory.count >= 5 else { return .unknown }
        
        let avgVelocity = velocityHistory.reduce(CGVector.zero) { result, velocity in
            CGVector(dx: result.dx + velocity.dx / Double(velocityHistory.count),
                    dy: result.dy + velocity.dy / Double(velocityHistory.count))
        }
        
        let speed = sqrt(avgVelocity.dx * avgVelocity.dx + avgVelocity.dy * avgVelocity.dy)
        
        if speed < 10 {
            return .tap
        } else if abs(avgVelocity.dx) > abs(avgVelocity.dy) * 2 {
            return .swipeHorizontal
        } else if abs(avgVelocity.dy) > abs(avgVelocity.dx) * 2 {
            return .swipeVertical
        } else {
            return .pan
        }
    }
    
    enum GestureType {
        case tap
        case swipeHorizontal
        case swipeVertical
        case pan
        case unknown
    }
}

// MARK: - Anticipation View Modifier
struct AnticipationModifier: ViewModifier {
    @StateObject private var anticipationEngine = GestureAnticipationEngine.shared
    @State private var localHoverLocation: CGPoint = .zero
    @State private var isHovering = false
    @State private var glowOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0
    
    let onPredict: ((CGPoint) -> Void)?
    
    init(onPredict: ((CGPoint) -> Void)? = nil) {
        self.onPredict = onPredict
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isHovering {
                        // Anticipation glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(0.3 * glowOpacity),
                                        Color.blue.opacity(0.1 * glowOpacity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .position(localHoverLocation)
                            .allowsHitTesting(false)
                        
                        // Ripple effect for predicted touch point
                        if let predictedPoint = anticipationEngine.predictedTouchPoint {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 30 * rippleScale, height: 30 * rippleScale)
                                .position(predictedPoint)
                                .allowsHitTesting(false)
                        }
                    }
                }
            )
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    withAnimation(.easeIn(duration: 0.2)) {
                        glowOpacity = 1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        glowOpacity = 0
                    }
                    anticipationEngine.resetAnticipation()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        localHoverLocation = value.location
                        let velocity = CGVector(
                            dx: value.predictedEndLocation.x - value.location.x,
                            dy: value.predictedEndLocation.y - value.location.y
                        )
                        
                        anticipationEngine.updateGestureTracking(
                            location: value.location,
                            velocity: velocity
                        )
                        
                        // Animate ripple at predicted point
                        if anticipationEngine.gestureConfidence > 0.7 {
                            withAnimation(.easeOut(duration: 0.3).repeatForever(autoreverses: false)) {
                                rippleScale = 2
                            }
                        }
                    }
                    .onEnded { _ in
                        anticipationEngine.resetAnticipation()
                        rippleScale = 0
                    }
            )
            .onChange(of: anticipationEngine.predictedTouchPoint) { _, newValue in
                if let point = newValue {
                    onPredict?(point)
                }
            }
    }
}

// MARK: - Haptic Manager Extension
extension HapticManager {
    func playAnticipationPattern(intensity: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        // Use impact as anticipation feedback since engine is private
        let feedbackIntensity = CGFloat(intensity)
        impact(.light, intensity: feedbackIntensity)
    }
}

// MARK: - Interactive Preview View
struct GestureAnticipationPreview: View {
    @State private var predictedPoint: CGPoint?
    @State private var tapCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Gesture Anticipation Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Hover or drag to see prediction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 300)
                    .modifier(AnticipationModifier { point in
                        predictedPoint = point
                    })
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            tapCount += 1
                        }
                        
                        // Reset after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            tapCount = 0
                        }
                    }
                
                if tapCount > 0 {
                    Text("+\(tapCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .scaleEffect(tapCount > 0 ? 1.5 : 1)
                        .opacity(tapCount > 0 ? 1 : 0)
                }
            }
            
            if let point = predictedPoint {
                Text("Predicted: (\(Int(point.x)), \(Int(point.y)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - View Extension
extension View {
    func gestureAnticipation(onPredict: ((CGPoint) -> Void)? = nil) -> some View {
        modifier(AnticipationModifier(onPredict: onPredict))
    }
}

// MARK: - Advanced Anticipation Effects
struct AdvancedAnticipationView<Content: View>: View {
    let content: Content
    @State private var magneticField: [MagneticPoint] = []
    @State private var fieldStrength: Double = 0
    
    struct MagneticPoint: Identifiable, Equatable {
        let id = UUID()
        var position: CGPoint
        var strength: Double
        var radius: Double
        
        static func == (lhs: MagneticPoint, rhs: MagneticPoint) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            // Magnetic field visualization
            Canvas { context, size in
                for point in magneticField {
                    let gradient = Gradient(colors: [
                        Color.purple.opacity(point.strength),
                        Color.blue.opacity(point.strength * 0.5),
                        Color.clear
                    ])
                    
                    context.fill(
                        Circle()
                            .path(in: CGRect(
                                x: point.position.x - point.radius,
                                y: point.position.y - point.radius,
                                width: point.radius * 2,
                                height: point.radius * 2
                            )),
                        with: .radialGradient(
                            gradient,
                            center: point.position,
                            startRadius: 0,
                            endRadius: point.radius
                        )
                    )
                }
            }
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.3), value: magneticField)
        }
        .gestureAnticipation { predictedPoint in
            updateMagneticField(at: predictedPoint)
        }
    }
    
    private func updateMagneticField(at point: CGPoint) {
        let newPoint = MagneticPoint(
            position: point,
            strength: 0.3,
            radius: 50
        )
        
        magneticField.append(newPoint)
        
        // Fade out old points
        if magneticField.count > 5 {
            magneticField.removeFirst()
        }
        
        // Update field strength
        withAnimation(.easeIn(duration: 0.2)) {
            fieldStrength = min(Double(magneticField.count) / 5.0, 1.0)
        }
    }
}

#Preview {
    GestureAnticipationPreview()
}