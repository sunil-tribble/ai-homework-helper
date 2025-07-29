import UIKit
import CoreHaptics

/// Manages all haptic feedback throughout the app
@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
        
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Simple Haptics
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        default:
            impactMedium.impactOccurred()
        }
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Custom Haptic Patterns
    
    func playSuccessPattern() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            notification(.success)
            return
        }
        
        do {
            let pattern = try createSuccessPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            notification(.success)
        }
    }
    
    // MARK: - Liquid Glass Haptic Patterns
    
    func playGlassTouch() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.light)
            return
        }
        
        do {
            let pattern = try createGlassTouchPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.light)
        }
    }
    
    func playLiquidFlow() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.medium)
            return
        }
        
        do {
            let pattern = try createLiquidFlowPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.medium)
        }
    }
    
    func playDepthTransition(from: CGFloat, to: CGFloat) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.medium)
            return
        }
        
        do {
            let pattern = try createDepthTransitionPattern(from: from, to: to)
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.medium)
        }
    }
    
    func playElasticSnap() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.heavy)
            return
        }
        
        do {
            let pattern = try createElasticSnapPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.heavy)
        }
    }
    
    func playRipple(intensity: Float = 0.5) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.light)
            return
        }
        
        do {
            let pattern = try createRipplePattern(intensity: intensity)
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.light)
        }
    }
    
    func playStreakCelebration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            notification(.success)
            return
        }
        
        do {
            let pattern = try createStreakPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            notification(.success)
        }
    }
    
    func playBounce() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(.light)
            return
        }
        
        do {
            let pattern = try createBouncePattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.light)
        }
    }
    
    func playUnlockPattern() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            notification(.success)
            return
        }
        
        do {
            let pattern = try createUnlockPattern()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            notification(.success)
        }
    }
    
    // MARK: - Pattern Creators
    
    private func createSuccessPattern() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        
        return try CHHapticPattern(events: [event1, event2], parameters: [])
    }
    
    private func createStreakPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Build up pattern
        for i in 0..<5 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i) * 0.2)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: TimeInterval(i) * 0.1)
            events.append(event)
        }
        
        // Celebration burst
        let finalIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let finalSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let finalEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [finalIntensity, finalSharpness], relativeTime: 0.6)
        events.append(finalEvent)
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func createBouncePattern() throws -> CHHapticPattern {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        return try CHHapticPattern(events: [event], parameters: [])
    }
    
    private func createUnlockPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Quick taps building up
        for i in 0..<3 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: TimeInterval(i) * 0.05)
            events.append(event)
        }
        
        // Success burst
        let successIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let successSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let successEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [successIntensity, successSharpness], relativeTime: 0.2)
        events.append(successEvent)
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    // MARK: - Liquid Glass Pattern Creators
    
    private func createGlassTouchPattern() throws -> CHHapticPattern {
        // Crisp, delicate feedback that suggests touching glass
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        
        return try CHHapticPattern(events: [event], parameters: [])
    }
    
    private func createLiquidFlowPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Create a flowing sensation with varying intensity
        for i in 0..<8 {
            let time = TimeInterval(i) * 0.05
            let intensity = sin(Double(i) * .pi / 4) * 0.5 + 0.3
            
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: time)
            events.append(event)
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func createDepthTransitionPattern(from: CGFloat, to: CGFloat) throws -> CHHapticPattern {
        let depthDifference = abs(to - from)
        let isAscending = to > from
        
        var events: [CHHapticEvent] = []
        
        if isAscending {
            // Rising sensation
            for i in 0..<3 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.2 + depthDifference * 0.3))
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.7 - Double(i) * 0.2))
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: TimeInterval(i) * 0.05)
                events.append(event)
            }
        } else {
            // Settling sensation
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + depthDifference * 0.3))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            events.append(event)
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func createElasticSnapPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Build tension
        for i in 0..<2 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2 + Float(i) * 0.1)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: TimeInterval(i) * 0.05)
            events.append(event)
        }
        
        // Snap release
        let snapIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let snapSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95)
        let snapEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [snapIntensity, snapSharpness], relativeTime: 0.15)
        events.append(snapEvent)
        
        // Settle
        let settleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
        let settleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        let settleEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [settleIntensity, settleSharpness], relativeTime: 0.2)
        events.append(settleEvent)
        
        return try CHHapticPattern(events: events, parameters: [])
    }
    
    private func createRipplePattern(intensity: Float) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        // Create expanding ripple effect
        for i in 0..<5 {
            let time = TimeInterval(i) * 0.08
            let rippleIntensity = intensity * (1.0 - Float(i) * 0.2)
            
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: rippleIntensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4 - Float(i) * 0.08)
            
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: time)
            events.append(event)
        }
        
        return try CHHapticPattern(events: events, parameters: [])
    }
}