import SwiftUI

struct ResourceCard: View {
    let resource: LearningResource
    @State private var isPressed = false
    
    var body: some View {
        Link(destination: URL(string: resource.url)!) {
            HStack(spacing: 12) {
                Image(systemName: resource.icon)
                    .font(.title3)
                    .foregroundColor(resource.type.color)
                    .frame(width: 40, height: 40)
                    .background(resource.type.color.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(resource.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(resource.type.color)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(resource.type.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1) {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ResourceCard(
            resource: LearningResource(
                title: "Khan Academy - Math",
                type: .video,
                url: "https://www.khanacademy.org/math",
                description: "Free video lessons and practice",
                icon: "play.rectangle.fill"
            )
        )
        
        ResourceCard(
            resource: LearningResource(
                title: "Physics Classroom",
                type: .article,
                url: "https://www.physicsclassroom.com",
                description: "Interactive physics tutorials",
                icon: "atom"
            )
        )
        
        ResourceCard(
            resource: LearningResource(
                title: "Desmos Calculator",
                type: .interactive,
                url: "https://www.desmos.com/calculator",
                description: "Graph equations visually",
                icon: "chart.line.uptrend.xyaxis"
            )
        )
    }
    .padding()
}