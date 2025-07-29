import SwiftUI

/// Reusable loading state view with various styles
struct LoadingStateView: View {
    let style: LoadingStyle
    let message: String?
    
    @State private var animationProgress: CGFloat = 0
    @State private var dotScale: [CGFloat] = [1, 1, 1]
    @State private var brainPulse = false
    
    init(style: LoadingStyle = .default, message: String? = nil) {
        self.style = style
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            switch style {
            case .default:
                defaultLoader
            case .brain:
                brainLoader
            case .dots:
                dotsLoader
            case .progress:
                progressLoader
            case .minimal:
                minimalLoader
            }
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .shimmer()
            }
        }
        .padding()
    }
    
    private var defaultLoader: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, value: animationProgress)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationProgress = 1
            }
        }
    }
    
    private var brainLoader: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(brainPulse ? 1.3 : 0.8)
                .opacity(brainPulse ? 0.3 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: brainPulse)
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(brainPulse ? 1.1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true), value: brainPulse)
            
            // Orbiting dots
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .offset(x: 40)
                    .rotationEffect(.degrees(Double(index) * 120 + animationProgress * 360))
            }
        }
        .onAppear {
            brainPulse = true
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationProgress = 1
            }
        }
    }
    
    private var dotsLoader: some View {
        HStack(spacing: 12) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 16, height: 16)
                    .scaleEffect(dotScale[index])
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: dotScale[index]
                    )
            }
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    dotScale[i] = 1.5
                }
            }
        }
    }
    
    private var progressLoader: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200 * animationProgress, height: 8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationProgress)
            }
            .frame(width: 200)
            
            Text("\(Int(animationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .onAppear {
            animationProgress = 0.9
        }
    }
    
    private var minimalLoader: some View {
        ProgressView()
            .scaleEffect(1.5)
            .tint(.blue)
    }
}

enum LoadingStyle {
    case `default`
    case brain
    case dots
    case progress
    case minimal
}

/// Skeleton loading view for content placeholders
struct SkeletonLoadingView: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 30)
                .frame(maxWidth: 200)
                .shimmer()
            
            // Content skeletons
            ForEach(0..<3) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .frame(maxWidth: 250)
                        .shimmer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingStateView(style: .default, message: "Loading...")
        LoadingStateView(style: .brain, message: "Processing with AI...")
        LoadingStateView(style: .dots)
        LoadingStateView(style: .progress, message: "Analyzing problem...")
        LoadingStateView(style: .minimal)
        
        SkeletonLoadingView()
    }
}