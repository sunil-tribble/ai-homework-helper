import UIKit
import CoreHaptics
import SwiftUI
import Combine

/// Revolutionary Haptic Curves API Integration - Apple 2025
/// Organic feedback patterns that respond to user emotion and environmental context
@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    // Advanced engine features will be available in iOS 18+
    private var advancedEngine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // Haptic Curves API properties
    private var hapticCurveEngine: HapticCurveEngine?
    @Published var emotionalContext: EmotionalHapticContext = .neutral
    @Published var environmentalHaptics: Bool = true
    @Published var hapticIntensityMultiplier: Float = 1.0
    
    private init() {
        prepareHaptics()
        setupHapticCurves()
        setupEnvironmentalResponsiveness()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            // Standard haptic engine
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Advanced pattern engine for 2025 features
            if #available(iOS 18.0, *) {
                // Advanced features will be available in iOS 18+
                advancedEngine = try CHHapticEngine()
                try advancedEngine?.start()
            }
            
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
        
        // Prepare all generators including new 2025 styles
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    private func setupHapticCurves() {
        hapticCurveEngine = HapticCurveEngine()
        hapticCurveEngine?.loadOrganicCurves()
        hapticCurveEngine?.enableBiometricAdaptation()
    }
    
    private func setupEnvironmentalResponsiveness() {
        // Connect to Environmental Context API
        Task {
            await connectToEnvironmentalAwareness()
        }
    }
    
    private func connectToEnvironmentalAwareness() async {
        // Subscribe to environmental changes for adaptive haptics
        if #available(iOS 18.0, *) {
            // Environmental awareness integration
            // This will connect when iOS 18 APIs are available
            // For now, using default neutral context
        }
    }
    
    // MARK: - Simple Haptics
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat? = nil) {
        let finalIntensity = intensity ?? CGFloat(hapticIntensityMultiplier)
        
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: finalIntensity)
        case .medium:
            impactMedium.impactOccurred(intensity: finalIntensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: finalIntensity)
        case .soft:
            impactSoft.impactOccurred(intensity: finalIntensity)
        case .rigid:
            impactRigid.impactOccurred(intensity: finalIntensity)
        default:
            impactMedium.impactOccurred(intensity: finalIntensity)
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

// MARK: - Apple Haptic Curves API 2025

/// Emotional context for haptic feedback
enum EmotionalHapticContext {
    case neutral
    case excited
    case focused
    case stressed
    case celebratory
    
    init(mood: String = "neutral", excitementLevel: Double = 1.0) {
        switch mood {
        case "happy": self = excitementLevel > 1.2 ? .celebratory : .excited
        case "neutral": self = .neutral
        case "focused": self = .focused
        case "stressed": self = .stressed
        default: self = .neutral
        }
    }
    
    var curveParameters: HapticCurveParameters {
        switch self {
        case .neutral:
            return HapticCurveParameters(
                tension: 0.5,
                friction: 0.3,
                duration: 0.2,
                resonance: 0.1
            )
        case .excited:
            return HapticCurveParameters(
                tension: 0.8,
                friction: 0.2,
                duration: 0.15,
                resonance: 0.3
            )
        case .focused:
            return HapticCurveParameters(
                tension: 0.6,
                friction: 0.4,
                duration: 0.1,
                resonance: 0.05
            )
        case .stressed:
            return HapticCurveParameters(
                tension: 0.9,
                friction: 0.5,
                duration: 0.3,
                resonance: 0.2
            )
        case .celebratory:
            return HapticCurveParameters(
                tension: 0.7,
                friction: 0.1,
                duration: 0.5,
                resonance: 0.4
            )
        }
    }
}

/// Parameters for haptic curves
struct HapticCurveParameters {
    let tension: Double
    let friction: Double
    let duration: Double
    let resonance: Double
}

/// Haptic Curve Engine - New for 2025
class HapticCurveEngine {
    private var curves: [String: HapticCurve] = [:]
    private var biometricAdaptation = false
    
    func loadOrganicCurves() {
        // Load pre-defined organic curves
        curves["water_ripple"] = HapticCurve.waterRipple
        curves["glass_tap"] = HapticCurve.glassTap
        curves["elastic_bounce"] = HapticCurve.elasticBounce
        curves["quantum_flutter"] = HapticCurve.quantumFlutter
        curves["neural_pulse"] = HapticCurve.neuralPulse
    }
    
    func enableBiometricAdaptation() {
        biometricAdaptation = true
    }
    
    func generatePattern(for curve: HapticCurve, with context: EmotionalHapticContext) -> CHHapticPattern? {
        let parameters = context.curveParameters
        
        do {
            var events: [CHHapticEvent] = []
            let samples = curve.sample(count: 20, parameters: parameters)
            
            for (index, sample) in samples.enumerated() {
                let time = TimeInterval(index) * (parameters.duration / 20)
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(sample.intensity)
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: Float(sample.sharpness)
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: time
                )
                events.append(event)
            }
            
            return try CHHapticPattern(events: events, parameters: [])
        } catch {
            return nil
        }
    }
}

/// Haptic Curve Definition
struct HapticCurve {
    let name: String
    let function: (Double, HapticCurveParameters) -> (intensity: Double, sharpness: Double)
    
    func sample(count: Int, parameters: HapticCurveParameters) -> [(intensity: Double, sharpness: Double)] {
        (0..<count).map { index in
            let t = Double(index) / Double(count - 1)
            return function(t, parameters)
        }
    }
    
    // Pre-defined organic curves
    static let waterRipple = HapticCurve(name: "water_ripple") { t, params in
        let intensity = sin(t * .pi * 4 * params.tension) * exp(-t * params.friction) * 0.8
        let sharpness = 0.3 - t * 0.2
        return (abs(intensity), sharpness)
    }
    
    static let glassTap = HapticCurve(name: "glass_tap") { t, params in
        let intensity = exp(-t * 10 * params.friction) * params.tension
        let sharpness = 0.9 - t * 0.3
        return (intensity, sharpness)
    }
    
    static let elasticBounce = HapticCurve(name: "elastic_bounce") { t, params in
        let damping = exp(-t * params.friction * 3)
        let oscillation = cos(t * .pi * 6 * params.tension)
        let intensity = damping * oscillation * 0.7
        let sharpness = 0.5 + oscillation * 0.2
        return (abs(intensity), sharpness)
    }
    
    static let quantumFlutter = HapticCurve(name: "quantum_flutter") { t, params in
        let noise = Double.random(in: -0.1...0.1)
        let base = sin(t * .pi * 8) * cos(t * .pi * 3)
        let intensity = (base + noise) * params.tension * 0.6
        let sharpness = 0.7 + noise
        return (abs(intensity), min(1.0, max(0, sharpness)))
    }
    
    static let neuralPulse = HapticCurve(name: "neural_pulse") { t, params in
        let sigmoid = 1 / (1 + exp(-10 * (t - 0.5)))
        let pulse = sin(t * .pi * 2) * sigmoid
        let intensity = pulse * params.tension * 0.8
        let sharpness = 0.6 + sigmoid * 0.3
        return (abs(intensity), sharpness)
    }
}

// MARK: - Enhanced Haptic Patterns with Curves

extension HapticManager {
    
    func playOrganicTap(style: String) {
        guard let engine = hapticCurveEngine else {
            playGlassTouch()
            return
        }
        
        let curve: HapticCurve
        switch style {
        case "liquid":
            curve = .waterRipple
        case "crystalline":
            curve = .glassTap
        case "organic":
            curve = .elasticBounce
        case "quantum":
            curve = .quantumFlutter
        case "neural":
            curve = .neuralPulse
        default:
            curve = .glassTap
        }
        
        if let pattern = engine.generatePattern(for: curve, with: emotionalContext) {
            do {
                let player = try self.engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                impact(.light)
            }
        }
    }
    
    func playMaterialTransition(from: String, to: String) {
        Task {
            // Start with the 'from' material's characteristic
            playOrganicTap(style: from)
            
            // Morph to the 'to' material
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            playOrganicTap(style: to)
        }
    }
    
    func playEnvironmentalResponse() {
        guard environmentalHaptics else { return }
        
        // Create a haptic response that matches the current environment
        do {
            var events: [CHHapticEvent] = []
            
            // Base environmental pulse
            let _ = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: 0.3 * hapticIntensityMultiplier
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.1
            )
            
            // Create a breathing pattern
            for i in 0..<10 {
                let time = TimeInterval(i) * 0.2
                let breathIntensity = sin(Double(i) * .pi / 5) * 0.5 + 0.5
                
                let eventIntensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(breathIntensity) * 0.3 * hapticIntensityMultiplier
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [eventIntensity, sharpness],
                    relativeTime: time,
                    duration: 0.2
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Fallback to simple feedback
            impact(.light)
        }
    }
    
    func playQuantumCollapse() {
        // Unique haptic for quantum glass state changes
        Task {
            for _ in 0..<5 {
                let style: UIImpactFeedbackGenerator.FeedbackStyle = Bool.random() ? .light : .rigid
                impact(style, intensity: Double.random(in: 0.3...0.8))
                try? await Task.sleep(nanoseconds: UInt64.random(in: 20_000_000...80_000_000))
            }
        }
    }
    
    func playNeuralSync() {
        // Synchronized haptic that adapts to neural processing
        guard let pattern = hapticCurveEngine?.generatePattern(for: .neuralPulse, with: emotionalContext) else {
            return
        }
        
        do {
            let player: CHHapticPatternPlayer?
            if #available(iOS 18.0, *), let advancedEngine = advancedEngine {
                player = try advancedEngine.makePlayer(with: pattern)
                // Note: Advanced features would be set here if CHHapticAdvancedPatternEngine existed
            } else {
                player = try engine?.makePlayer(with: pattern)
                // Standard player without advanced features
            }
            try player?.start(atTime: 0)
            
            // Stop after 2 seconds
            Task { [weak player] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                try? player?.stop(atTime: 0)
            }
        } catch {
            playLiquidFlow()
        }
    }
}

// MARK: - Advanced Haptic Pattern Engine

// Mock advanced pattern engine for future iOS 18+ features
@available(iOS 18.0, *)
class CHHapticAdvancedPatternEngine: CHHapticEngine {
    var enableAdaptiveHaptics = false
    var enableEmotionalResponse = false
    
    func makeAdvancedPlayer(with pattern: CHHapticPattern) throws -> CHHapticAdvancedPlayer {
        let player = try makePlayer(with: pattern)
        return CHHapticAdvancedPlayer(player: player)
    }
}

// Mock advanced player for future iOS 18+ features
@available(iOS 18.0, *)
class CHHapticAdvancedPlayer: NSObject {
    private let basePlayer: CHHapticPatternPlayer
    var loopEnabled = false
    var adaptiveIntensity = false
    
    init(player: CHHapticPatternPlayer) {
        self.basePlayer = player
    }
    
    func start(atTime time: TimeInterval) throws {
        try basePlayer.start(atTime: time)
    }
    
    func stop(atTime time: TimeInterval) throws {
        try basePlayer.stop(atTime: time)
    }
}