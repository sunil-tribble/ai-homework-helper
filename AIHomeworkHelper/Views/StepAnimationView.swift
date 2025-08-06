import SwiftUI

struct StepAnimationView: View {
    let step: String
    let stepNumber: Int
    let isVisible: Bool
    let progress: CGFloat
    
    @State private var equationParts: [EquationPart] = []
    @State private var showExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Step header
            HStack {
                Circle()
                    .fill(isVisible ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("\(stepNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                
                Text("Step \(stepNumber)")
                    .font(.headline)
                    .foregroundColor(isVisible ? .primary : .secondary)
                
                Spacer()
                
                if isVisible && progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale)
                }
            }
            .opacity(isVisible ? 1.0 : 0.5)
            
            if isVisible {
                // Animated equation or content
                if let equation = extractEquation(from: step) {
                    AnimatedEquationView(
                        equation: equation,
                        progress: progress
                    )
                } else {
                    // Regular text animation
                    Text(step)
                        .font(.body)
                        .opacity(progress)
                        .offset(x: (1 - progress) * 20)
                }
                
                // Explanation bubble
                if progress >= 0.8 && extractExplanation(from: step) != nil {
                    ExplanationBubble(
                        text: extractExplanation(from: step) ?? "",
                        isVisible: progress >= 1.0
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .identity
                    ))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isVisible ? Color.blue.opacity(0.05) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isVisible ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1),
                            lineWidth: isVisible ? 2 : 1
                        )
                )
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .animation(.easeInOut(duration: 0.5), value: progress)
    }
    
    private func extractEquation(from text: String) -> String? {
        // Simple equation detection - looks for mathematical expressions
        let patterns = [
            ".*=.*",           // Contains equals sign
            ".*[+\\-*/].*",    // Contains operators
            ".*\\d+.*"         // Contains numbers
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let equation = String(text[range])
                if equation.count > 2 && equation.count < 50 {
                    return equation
                }
            }
        }
        
        return nil
    }
    
    private func extractExplanation(from text: String) -> String? {
        // Extract explanation part (after colon or parentheses)
        if let colonRange = text.range(of: ":"), colonRange.upperBound < text.endIndex {
            return String(text[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        
        if let parenRange = text.range(of: "("), parenRange.lowerBound < text.endIndex {
            return String(text[parenRange.lowerBound...])
        }
        
        return nil
    }
}

struct AnimatedEquationView: View {
    let equation: String
    let progress: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(parseEquationParts(equation), id: \.id) { part in
                EquationPartView(part: part, progress: progress)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func parseEquationParts(_ equation: String) -> [EquationPart] {
        var parts: [EquationPart] = []
        let components = equation.components(separatedBy: .whitespaces)
        
        for (index, component) in components.enumerated() {
            let delay = Double(index) * 0.2
            
            if Double(component) != nil {
                parts.append(EquationPart(
                    id: UUID(),
                    content: component,
                    type: .number,
                    delay: delay
                ))
            } else if ["+", "-", "*", "/", "=", "(", ")"].contains(component) {
                parts.append(EquationPart(
                    id: UUID(),
                    content: component,
                    type: .`operator`,
                    delay: delay
                ))
            } else {
                parts.append(EquationPart(
                    id: UUID(),
                    content: component,
                    type: .variable,
                    delay: delay
                ))
            }
        }
        
        return parts
    }
}

struct EquationPartView: View {
    let part: EquationPart
    let progress: CGFloat
    
    private var partProgress: CGFloat {
        let adjustedProgress = max(0, (progress - part.delay) / (1 - part.delay))
        return min(1, adjustedProgress)
    }
    
    var body: some View {
        Text(part.content)
            .font(.system(size: 18, weight: part.type == .`operator` ? .medium : .regular, design: .rounded))
            .foregroundColor(part.type.color)
            .scaleEffect(0.5 + partProgress * 0.5)
            .opacity(partProgress)
            .offset(y: (1 - partProgress) * 10)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: partProgress)
    }
}

struct ExplanationBubble: View {
    let text: String
    let isVisible: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
    }
}

struct EquationPart: Identifiable {
    let id: UUID
    let content: String
    let type: EquationType
    let delay: Double
}

enum EquationType {
    case number
    case `operator`
    case variable
    
    var color: Color {
        switch self {
        case .number:
            return .blue
        case .`operator`:
            return .purple
        case .variable:
            return .green
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StepAnimationView(
            step: "Step 1: Simplify the equation\n2x + 3 = 7",
            stepNumber: 1,
            isVisible: true,
            progress: 1.0
        )
        
        StepAnimationView(
            step: "Step 2: Subtract 3 from both sides\n2x = 4",
            stepNumber: 2,
            isVisible: true,
            progress: 0.5
        )
        
        StepAnimationView(
            step: "Step 3: Divide by 2\nx = 2",
            stepNumber: 3,
            isVisible: false,
            progress: 0.0
        )
    }
    .padding()
}