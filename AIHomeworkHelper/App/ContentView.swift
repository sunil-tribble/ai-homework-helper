import SwiftUI
import RealityKit

// MARK: - Glass Style Definition
enum GlassStyle {
    case ultraThin
    case thin
    case regular
    case thick
    case frosted
    case liquid
    case crystalline
    case organic
    case quantum
    case neural
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var tabChangeAnimation = false
    @State private var glassStyle: GlassStyle = .neural
    
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        ZStack {
            // Dynamic Liquid Glass background with environmental awareness
            if #available(iOS 18.0, *) {
                LiquidGlassBackground()
                    .ignoresSafeArea()
                    .animation(.smooth(duration: 0.5), value: userManager.selectedTheme)
            } else {
                userManager.selectedTheme.backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: userManager.selectedTheme)
            }
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        TabItemView(
                            icon: "house.fill",
                            title: "Home",
                            isSelected: selectedTab == 0
                        )
                    }
                    .tag(0)
                    .applyLiquidGlass(style: glassStyle)
                
                ScannerView()
                    .tabItem {
                        TabItemView(
                            icon: "camera.fill",
                            title: "Scan",
                            isSelected: selectedTab == 1
                        )
                    }
                    .tag(1)
                    .applyLiquidGlass(style: glassStyle)
                
                HistoryView()
                    .tabItem {
                        TabItemView(
                            icon: "clock.fill",
                            title: "History",
                            isSelected: selectedTab == 2
                        )
                    }
                    .tag(2)
                    .applyLiquidGlass(style: glassStyle)
                
                ProfileView()
                    .tabItem {
                        TabItemView(
                            icon: "person.fill",
                            title: "Profile",
                            isSelected: selectedTab == 3
                        )
                    }
                    .tag(3)
                    .applyLiquidGlass(style: glassStyle)
            }
            .tint(userManager.selectedTheme.primaryColor)
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
            
            // Tab change particle effect
            if tabChangeAnimation {
                ParticleSystem(
                    particleCount: 15,
                    duration: 1.0,
                    particleSize: 6,
                    colors: [userManager.selectedTheme.primaryColor, userManager.selectedTheme.secondaryColor],
                    spread: 50,
                    emissionShape: .point
                )
                .allowsHitTesting(false)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)
            }
        }
        .preferredColorScheme(userManager.selectedTheme == .neon ? .dark : nil)
    }
    
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        // Haptic feedback
        hapticManager.selection()
        
        // Sound effect
        soundManager.play(.tap)
        
        // Trigger particle animation
        withAnimation(.easeOut(duration: 0.3)) {
            tabChangeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tabChangeAnimation = false
        }
        
        previousTab = oldTab
    }
}

struct TabItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    @State private var animateSelection = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .symbolEffect(.bounce, value: isSelected)
                .scaleEffect(isSelected ? 1.1 : 1.0)
            
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                animateSelection = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreKitManager())
        .environmentObject(UserManager())
}


// MARK: - Liquid Glass Background

@available(iOS 18.0, *)
struct LiquidGlassBackground: View {
    @StateObject private var environmentalAwareness = EnvironmentalAwareness.shared
    @StateObject private var performanceMetrics = PerformanceMetricsEngine.shared
    @State private var glassLayers: [GlassLayer] = []
    @State private var timeOffset: Double = 0
    
    var body: some View {
        ZStack {
            // Base gradient responsive to environmental light
            LinearGradient(
                colors: adaptiveColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Multiple liquid glass layers with parallax
            ForEach(glassLayers) { layer in
                LiquidGlassLayer(
                    layer: layer,
                    timeOffset: timeOffset,
                    performanceScale: performanceMetrics.thermalState.performanceScale
                )
                .offset(layer.offset)
                .blur(radius: layer.blurRadius)
                .opacity(layer.opacity)
            }
            
            // Neural network visualization overlay
            if performanceMetrics.neuralProcessingPower > 0.8 {
                NeuralNetworkOverlay()
                    .opacity(0.3)
                    .blendMode(.screen)
            }
        }
        .onAppear {
            generateGlassLayers()
            startAnimation()
        }
    }
    
    private var adaptiveColors: [Color] {
        switch environmentalAwareness.emotionalState.mood {
        case .happy:
            return [Color.blue.opacity(0.3), Color.purple.opacity(0.4), Color.pink.opacity(0.3)]
        case .focused:
            return [Color.indigo.opacity(0.4), Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]
        case .stressed:
            return [Color.red.opacity(0.2), Color.orange.opacity(0.3), Color.yellow.opacity(0.2)]
        case .neutral:
            return [Color.gray.opacity(0.3), Color.blue.opacity(0.2), Color.purple.opacity(0.2)]
        }
    }
    
    private func generateGlassLayers() {
        glassLayers = (0..<5).map { index in
            GlassLayer(
                id: index,
                offset: CGSize(
                    width: Double.random(in: -50...50),
                    height: Double.random(in: -50...50)
                ),
                scale: 1.0 + Double(index) * 0.1,
                blurRadius: Double(index) * 2,
                opacity: 0.3 - Double(index) * 0.05,
                animationSpeed: 1.0 + Double(index) * 0.2
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            timeOffset = 1.0
        }
    }
}

struct GlassLayer: Identifiable {
    let id: Int
    var offset: CGSize
    let scale: Double
    let blurRadius: Double
    let opacity: Double
    let animationSpeed: Double
}

@available(iOS 18.0, *)
struct LiquidGlassLayer: View {
    let layer: GlassLayer
    let timeOffset: Double
    let performanceScale: Double
    
    var body: some View {
        Canvas { context, size in
            let path = createLiquidPath(in: size)
            
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
        }
        .scaleEffect(layer.scale)
    }
    
    private func createLiquidPath(in size: CGSize) -> Path {
        var path = Path()
        
        let waveHeight = 50.0 * performanceScale
        let frequency = 2.0 * layer.animationSpeed
        
        path.move(to: .zero)
        
        for x in stride(from: 0, through: size.width, by: 5) {
            let relativeX = x / size.width
            let y = sin(relativeX * .pi * frequency + timeOffset * layer.animationSpeed * .pi * 2) * waveHeight + size.height / 2
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        
        return path
    }
}

@available(iOS 18.0, *)
struct NeuralNetworkOverlay: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<20) { _ in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: pulseAnimation ? 30 : 10
                        )
                    )
                    .frame(width: 20, height: 20)
                    .position(
                        x: .random(in: 0...geometry.size.width),
                        y: .random(in: 0...geometry.size.height)
                    )
                    .animation(
                        .easeInOut(duration: .random(in: 2...4))
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - View Extensions for Liquid Glass

extension View {
    @ViewBuilder
    func applyLiquidGlass(style: GlassStyle) -> some View {
        if #available(iOS 18.0, *) {
            self
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        } else {
            self
        }
    }
    
    func materialXGlass(style: GlassStyle, luminosity: Double, refractionIntensity: Double) -> some View {
        self.modifier(MaterialXGlassModifier(style: style, luminosity: luminosity, refractionIntensity: refractionIntensity))
    }
}

// MARK: - Custom Modifiers

struct MaterialXGlassModifier: ViewModifier {
    let style: GlassStyle
    let luminosity: Double
    let refractionIntensity: Double
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(luminosity * 0.2), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct InteractiveParallaxModifier: ViewModifier {
    let depth: Double
    let faceTracking: Bool
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(depth), axis: (x: 0, y: 1, z: 0))
    }
}