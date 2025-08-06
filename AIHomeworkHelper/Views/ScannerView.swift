import SwiftUI
import PhotosUI
import VisionKit
import Speech
import AVFoundation

@available(iOS 17.0, *)
struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var userManager: UserManager
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var showingPaywall = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scanAnimation = false
    @State private var glowAnimation = false
    @State private var showingVoiceInput = false
    @State private var subjectSelectionAnimation = false
    @State private var showWelcomeTip = true
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Scan Problem")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        resetButton
                    }
                }
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
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                }
                .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                    Button("OK") {
                        viewModel.error = nil
                    }
                } message: {
                    Text(viewModel.error ?? "")
                }
                .navigationDestination(isPresented: $viewModel.showingSolution) {
                    if let problem = viewModel.currentProblem {
                        SolutionView(problem: problem)
                    }
                }
                .sheet(isPresented: $showingVoiceInput) {
                    VoiceInputView(recognizedText: $viewModel.recognizedText) { text in
                        if !text.isEmpty {
                            viewModel.recognizedText = text
                            viewModel.processTextInput(text)
                            userManager.incrementSolveCount()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if viewModel.isProcessing {
                    processingView
                } else if let image = viewModel.scannedImage {
                    scannedImageView(image)
                } else {
                    scanOptionsView
                }
            }
        }
    }
    
    @ViewBuilder
    private var resetButton: some View {
        if viewModel.scannedImage != nil {
            Button("Reset") {
                viewModel.reset()
            }
        }
    }
    
    private var scanOptionsView: some View {
        VStack(spacing: 24) {
            // Subject Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Subject")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Subject.allCases, id: \.self) { subject in
                            SubjectChip(
                                subject: subject,
                                isSelected: viewModel.selectedSubject == subject
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedSubject = subject
                                }
                                hapticManager.selection()
                                soundManager.play(.tap)
                                
                                // Hide welcome tip after first selection
                                if showWelcomeTip {
                                    withAnimation {
                                        showWelcomeTip = false
                                    }
                                }
                            }
                            .scaleEffect(subjectSelectionAnimation && viewModel.selectedSubject == subject ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: subjectSelectionAnimation)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Scan Options
            VStack(spacing: 20) {
                ScanOptionCard(
                    icon: "doc.text.viewfinder",
                    title: "Scan Document",
                    description: "Use camera to scan homework",
                    color: .blue
                )
                .onTapGesture {
                    checkAndProceed {
                        showingDocumentScanner = true
                    }
                }
                
                ScanOptionCard(
                    icon: "photo.on.rectangle",
                    title: "Choose Photo",
                    description: "Select from photo library",
                    color: .green
                )
                .onTapGesture {
                    checkAndProceed {
                        showingImagePicker = true
                    }
                }
                
                ScanOptionCard(
                    icon: "mic.fill",
                    title: "Voice Input",
                    description: "Speak your problem",
                    color: .red
                )
                .onTapGesture {
                    checkAndProceed {
                        showingVoiceInput = true
                    }
                }
            }
            .padding(.horizontal)
            
            // Welcome tip for first-time users
            if showWelcomeTip && userManager.totalSolves == 0 {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .symbolEffect(.pulse, value: showWelcomeTip)
                    Text("Select a subject to get started!")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showWelcomeTip = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            Spacer()
            
            // Usage Info with Smart Nudge
            if !userManager.isPremium {
                VStack(spacing: 12) {
                    // Show different nudges based on usage
                    if userManager.solvesRemaining <= 2 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Only \(userManager.solvesRemaining) solves left today!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Image(systemName: "infinity")
                                Text("Go Unlimited for $4.99/mo")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        
                        Text("Join 50M+ students solving unlimited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(userManager.solvesRemaining) free solves remaining today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Upgrade for Unlimited Solves") {
                            showingPaywall = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(scanAnimation ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: scanAnimation)
                
                ZStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    
                    // Animated particles while processing
                    ParticleSystem(
                        particleCount: 12,
                        duration: 2.0,
                        particleSize: 4,
                        colors: [.blue, .purple, .indigo],
                        spread: 60,
                        emissionShape: .circle(radius: 40)
                    )
                }
            }
            .onAppear {
                scanAnimation = true
            }
            
            Text("Processing your homework...")
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shimmer()
            
            Text("Using AI to analyze your problem")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.purple.opacity(0.2), radius: 15, x: 0, y: 10)
    }
    
    private func scannedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
            
            if !viewModel.recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognized Text:")
                        .font(.headline)
                    
                    Text(viewModel.recognizedText)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                checkAndProceed {
                    viewModel.processImage(image)
                }
            }) {
                Label("Get Solution", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func checkAndProceed(action: @escaping () -> Void) {
        if userManager.canSolve {
            hapticManager.impact(.medium)
            soundManager.play(.success)
            action()
        } else {
            hapticManager.notification(.warning)
            soundManager.play(.error)
            showingPaywall = true
        }
    }
    
    private func handleScannedImage(_ image: UIImage) {
        viewModel.scannedImage = image
        viewModel.processImage(image)
        userManager.incrementSolveCount()
        // Haptic and sound feedback
        HapticManager.shared.playSuccessPattern()
        SoundManager.shared.play(.scanComplete)
    }
}

@available(iOS 17.0, *)
struct SubjectChip: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: subject.icon)
            Text(subject.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    subject.color
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                }
            }
        )
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isSelected ? Color.white.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(color: isSelected ? subject.color.opacity(0.4) : Color.clear, radius: 5)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            action()
        }
    }
}

@available(iOS 17.0, *)
struct ScanOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    ZStack {
                        color
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .cornerRadius(12)
                .shadow(color: color.opacity(0.3), radius: isPressed ? 8 : 4)
                .scaleEffect(isPressed ? 1.05 : 1.0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .offset(x: isPressed ? 5 : 0)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

@available(iOS 17.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                controller.dismiss(animated: true)
                return
            }
            
            let image = scan.imageOfPage(at: 0)
            controller.dismiss(animated: true) {
                self.completion(image)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}

@available(iOS 17.0, *)
struct VoiceInputView: View {
    @Binding var recognizedText: String
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var recordingAnimation = false
    @State private var audioLevel: CGFloat = 0
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Voice visualization
                    ZStack {
                        // Pulsing circles
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.5), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 150 + CGFloat(index) * 50, height: 150 + CGFloat(index) * 50)
                                .scaleEffect(isRecording ? 1.0 + audioLevel * 0.3 : 0.8)
                                .opacity(isRecording ? 0.6 - Double(index) * 0.2 : 0.3)
                                .animation(
                                    isRecording ? 
                                    .easeInOut(duration: 0.5 + Double(index) * 0.2).repeatForever(autoreverses: true) :
                                    .easeOut(duration: 0.3),
                                    value: isRecording
                                )
                        }
                        
                        // Microphone button
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isRecording ? [Color.red, Color.red.opacity(0.8)] : [Color.gray.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce, value: isRecording)
                            }
                        }
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isRecording)
                    }
                    
                    // Status text
                    Text(isRecording ? "Listening..." : "Tap to speak your problem")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Recognized text
                    if !recognizedText.isEmpty {
                        VStack(spacing: 16) {
                            Text("Recognized:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView {
                                Text(recognizedText)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            .frame(maxHeight: 150)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { 
                            recognizedText = ""
                            if isRecording {
                                stopRecording()
                            }
                        }) {
                            Text("Clear")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }
                        .disabled(recognizedText.isEmpty)
                        
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            }
                            onComplete(recognizedText)
                            dismiss()
                        }) {
                            Text("Use This Text")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(recognizedText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        if isRecording {
                            stopRecording()
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            requestSpeechPermission()
        }
        .alert("Speech Recognition", isPresented: $showingPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("Please enable speech recognition in Settings to use voice input.")
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // Ready to go
                    break
                case .denied, .restricted:
                    showingPermissionAlert = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Reset previous session
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizedText = ""
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            // Update audio level for visualization
            let channelData = buffer.floatChannelData?[0]
            let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelData?[$0] ?? 0 }
            let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
            
            DispatchQueue.main.async {
                self.audioLevel = CGFloat(rms) * 10
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine error: \(error)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        audioLevel = 0
    }
}

@available(iOS 17.0, *)
#Preview {
    ScannerView()
        .environmentObject(UserManager())
}