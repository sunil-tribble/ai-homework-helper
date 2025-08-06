import SwiftUI
import PhotosUI
import VisionKit

@available(iOS 17.0, *)
struct LiquidGlassScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var userManager: UserManager
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var showingPaywall = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scanAnimation = false
    @State private var selectedOption: ScanOption?
    @State private var cardDepth: DepthCard<AnyView>.DepthLevel = .raised
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    enum ScanOption: String, CaseIterable {
        case camera = "camera.fill"
        case photo = "photo.on.rectangle"
        case voice = "mic.fill"
        
        var title: String {
            switch self {
            case .camera: return "Scan Document"
            case .photo: return "Choose Photo"
            case .voice: return "Voice Input"
            }
        }
        
        var description: String {
            switch self {
            case .camera: return "Use camera to scan"
            case .photo: return "Select from library"
            case .voice: return "Speak your problem"
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .camera: return [.blue, .cyan]
            case .photo: return [.green, .mint]
            case .voice: return [.red, .orange]
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background with depth
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Subject selector with liquid animation
                        subjectSelector
                            .padding(.horizontal)
                        
                        // Main content area
                        if viewModel.isProcessing {
                            processingView
                        } else if let image = viewModel.scannedImage {
                            scannedImageView(image)
                        } else {
                            scanOptionsGrid
                        }
                        
                        // Usage indicator with glass effect
                        if !userManager.isPremium {
                            usageIndicator
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Scan Problem")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView { image in
                    handleScannedImage(image)
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        handleScannedImage(image)
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.showingSolution) {
                if let problem = viewModel.currentProblem {
                    SolutionView(problem: problem)
                }
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated orbs for depth
            GeometryReader { geometry in
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(
                            x: CGFloat.random(in: -100...max(100, geometry.size.width)),
                            y: CGFloat.random(in: -100...max(100, geometry.size.height))
                        )
                        .blur(radius: 30)
                        .animation(
                            .easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: scanAnimation
                        )
                }
            }
        }
        .onAppear { scanAnimation = true }
    }
    
    private var subjectSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Subject")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        SubjectChipLiquid(
                            subject: subject,
                            isSelected: viewModel.selectedSubject == subject
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedSubject = subject
                                hapticManager.playGlassTouch()
                                soundManager.play(.tap)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var scanOptionsGrid: some View {
        VStack(spacing: 20) {
            ForEach(ScanOption.allCases, id: \.self) { option in
                LiquidButton(
                    action: {
                        handleScanOption(option)
                    },
                    style: selectedOption == option ? .primary : .secondary
                ) {
                    HStack(spacing: 20) {
                        // Icon with glass effect
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: option.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)
                                )
                            
                            Image(systemName: option.rawValue)
                                .font(.title2)
                                .foregroundColor(.white)
                                .symbolEffect(.bounce, value: selectedOption == option)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(selectedOption == option ? 90 : 0))
                    }
                    .padding()
                }
                .liquidTransition(isVisible: true)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(option.hashValue) * 0.1), value: scanAnimation)
            }
        }
        .padding(.horizontal)
    }
    
    private var processingView: some View {
        MorphingGlassContainer {
            VStack(spacing: 24) {
                // Animated processing indicator
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple, .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 60 + CGFloat(index) * 20, height: 60 + CGFloat(index) * 20)
                            .rotationEffect(.degrees(Double(index) * 120))
                            .rotationEffect(.degrees(scanAnimation ? 360 : 0))
                            .animation(
                                .linear(duration: 2 + Double(index))
                                    .repeatForever(autoreverses: false),
                                value: scanAnimation
                            )
                            .opacity(0.8 - Double(index) * 0.2)
                    }
                    
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }
                
                VStack(spacing: 8) {
                    Text("Processing your homework")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Using AI to analyze the problem...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress particles
                ParticleSystem(
                    particleCount: 20,
                    duration: 3.0,
                    particleSize: 3,
                    colors: [.blue, .purple, .cyan],
                    spread: 100,
                    emissionShape: .circle(radius: 50)
                )
                .frame(height: 100)
            }
            .padding(40)
        }
        .frame(maxWidth: 350)
        .padding(.horizontal)
    }
    
    private var usageIndicator: some View {
        DepthCard(depth: .floating) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Solves")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(userManager.solvesRemaining) remaining")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: userManager.solvesRemaining <= 2 ? [.orange, .red] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Spacer()
                    
                    // Visual indicator
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(userManager.solvesRemaining) / 5.0)
                            .stroke(
                                LinearGradient(
                                    colors: userManager.solvesRemaining <= 2 ? [.orange, .red] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                    }
                }
                
                if userManager.solvesRemaining <= 2 {
                    LiquidButton(
                        action: { showingPaywall = true },
                        style: .primary
                    ) {
                        HStack {
                            Image(systemName: "infinity")
                            Text("Upgrade to Unlimited")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
    
    private func scannedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            DepthCard(depth: .elevated) {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    if !viewModel.recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recognized Text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.recognizedText)
                                .font(.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            LiquidButton(
                action: { viewModel.processImage(image) },
                style: .primary
            ) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Get Solution")
                }
                .font(.headline)
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            Button("Reset") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.reset()
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func handleScanOption(_ option: ScanOption) {
        hapticManager.playElasticSnap()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedOption = option
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            switch option {
            case .camera:
                showingDocumentScanner = true
            case .photo:
                showingImagePicker = true
            case .voice:
                // Handle voice input
                break
            }
            
            // Reset selection after action
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                selectedOption = nil
            }
        }
    }
    
    private func handleScannedImage(_ image: UIImage) {
        viewModel.scannedImage = image
        viewModel.processImage(image)
        userManager.incrementSolveCount()
        hapticManager.playSuccessPattern()
        soundManager.play(.scanComplete)
    }
}

// MARK: - Subject Chip with Liquid Glass
struct SubjectChipLiquid: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.subheadline)
                Text(subject.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        // Selected state with glass effect
                        RoundedRectangle(cornerRadius: 20)
                            .fill(subject.color)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .cornerRadius(20)
                            )
                    } else {
                        // Unselected state with subtle glass
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        subject.color.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            )
            .shadow(
                color: isSelected ? subject.color.opacity(0.4) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
}