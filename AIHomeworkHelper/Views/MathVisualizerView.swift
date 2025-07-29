import SwiftUI
import Charts

struct MathVisualizerView: View {
    let expression: String
    @State private var graphPoints: [(x: Double, y: Double)] = []
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoint: (x: Double, y: Double)?
    @State private var showDerivative = false
    @State private var showIntegral = false
    @State private var xRange: ClosedRange<Double> = -10...10
    @State private var yRange: ClosedRange<Double> = -10...10
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Expression display
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visualizing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(expression)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Interactive Graph
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                        
                        if !graphPoints.isEmpty {
                            Chart {
                                // Main function
                                ForEach(Array(graphPoints.enumerated()), id: \.offset) { index, point in
                                    LineMark(
                                        x: .value("X", point.x),
                                        y: .value("Y", point.y)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .opacity(Double(index) / Double(graphPoints.count) * animationProgress)
                                }
                                
                                // Selected point
                                if let selected = selectedPoint {
                                    PointMark(
                                        x: .value("X", selected.x),
                                        y: .value("Y", selected.y)
                                    )
                                    .foregroundStyle(Color.red)
                                    .symbolSize(200)
                                    .annotation(position: .top) {
                                        VStack(spacing: 2) {
                                            Text("(\(String(format: "%.2f", selected.x)), \(String(format: "%.2f", selected.y)))")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(6)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                    }
                                }
                            }
                            .chartXScale(domain: xRange)
                            .chartYScale(domain: yRange)
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            let x = chartProxy.value(atX: location.x, as: Double.self) ?? 0
                                            let y = findYValue(at: x)
                                            selectedPoint = (x: x, y: y)
                                        }
                                }
                            }
                            .padding()
                        } else {
                            ProgressView("Calculating...")
                                .padding()
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Controls
                    VStack(spacing: 16) {
                        // Feature toggles
                        HStack(spacing: 12) {
                            ToggleButton(
                                title: "Derivative",
                                icon: "function",
                                isOn: $showDerivative,
                                color: .green
                            )
                            
                            ToggleButton(
                                title: "Integral",
                                icon: "sum",
                                isOn: $showIntegral,
                                color: .orange
                            )
                            
                            ToggleButton(
                                title: "Animate",
                                icon: "play.fill",
                                isOn: .constant(false),
                                color: .purple
                            ) {
                                animateGraph()
                            }
                        }
                        
                        // Zoom controls
                        HStack {
                            Text("Zoom")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: .constant(1.0), in: 0.5...2.0)
                                .tint(.blue)
                            
                            Button(action: resetZoom) {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // Math insights
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            InsightCard(
                                title: "Domain",
                                value: "ℝ",
                                icon: "arrow.left.and.right",
                                color: .blue
                            )
                            
                            InsightCard(
                                title: "Range",
                                value: calculateRange(),
                                icon: "arrow.up.and.down",
                                color: .purple
                            )
                            
                            InsightCard(
                                title: "Zeros",
                                value: findZeros(),
                                icon: "circle.dotted",
                                color: .orange
                            )
                            
                            InsightCard(
                                title: "Min/Max",
                                value: findExtrema(),
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Math Visualizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            calculateGraph()
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func calculateGraph() {
        // Simple polynomial parsing for demo
        let xValues = stride(from: xRange.lowerBound, through: xRange.upperBound, by: 0.1)
        graphPoints = xValues.map { x in
            // For demo: parse simple expressions like "x^2 + 3x - 5"
            let y = evaluateExpression(expression, at: x)
            return (x: x, y: y)
        }
    }
    
    private func evaluateExpression(_ expr: String, at x: Double) -> Double {
        // Simplified expression evaluator for demo
        if expr.contains("x^2") {
            return x * x + 3 * x - 5
        } else if expr.contains("sin") {
            return sin(x)
        } else if expr.contains("cos") {
            return cos(x)
        } else {
            return x // Linear by default
        }
    }
    
    private func findYValue(at x: Double) -> Double {
        evaluateExpression(expression, at: x)
    }
    
    private func animateGraph() {
        animationProgress = 0
        withAnimation(.easeInOut(duration: 2.0)) {
            animationProgress = 1.0
        }
    }
    
    private func resetZoom() {
        withAnimation {
            xRange = -10...10
            yRange = -10...10
        }
    }
    
    private func calculateRange() -> String {
        let yValues = graphPoints.map { $0.y }
        if let min = yValues.min(), let max = yValues.max() {
            return "[\(String(format: "%.1f", min)), \(String(format: "%.1f", max))]"
        }
        return "ℝ"
    }
    
    private func findZeros() -> String {
        var zeros: [Double] = []
        for i in 1..<graphPoints.count {
            let prev = graphPoints[i-1]
            let curr = graphPoints[i]
            if prev.y * curr.y < 0 {
                // Sign change indicates a zero crossing
                zeros.append((prev.x + curr.x) / 2)
            }
        }
        if zeros.isEmpty {
            return "None"
        }
        return zeros.map { String(format: "%.1f", $0) }.joined(separator: ", ")
    }
    
    private func findExtrema() -> String {
        guard graphPoints.count > 2 else { return "N/A" }
        let yValues = graphPoints.map { $0.y }
        if let min = yValues.min(), let max = yValues.max() {
            return "Min: \(String(format: "%.1f", min)), Max: \(String(format: "%.1f", max))"
        }
        return "N/A"
    }
}

struct ToggleButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let action = action {
                action()
            } else {
                isOn.toggle()
            }
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isOn ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isOn ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color, lineWidth: isOn ? 0 : 1)
                    )
            )
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MathVisualizerView(expression: "x^2 + 3x - 5")
}