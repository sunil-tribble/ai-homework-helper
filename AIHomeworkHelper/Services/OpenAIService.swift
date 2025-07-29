import Foundation
import SwiftUI

class OpenAIService: ObservableObject {
    private let backendService = BackendService.shared
    
    func getSolution(for question: String, subject: Subject, imageData: Data? = nil) async throws -> String {
        // Use backend service instead of direct OpenAI API
        let response = try await backendService.solveProblem(
            question: question,
            subject: subject,
            imageData: imageData
        )
        
        // Update user stats if available
        // Note: In production, pass UserManager as dependency or use @EnvironmentObject
        // For now, stats are handled by the backend
        
        // Check if upgrade is required
        if response.dailySolvesRemaining == 0 {
            throw OpenAIError.dailyLimitReached
        }
        
        return response.solution
    }
    
    private func getSubjectSpecificPrompt(for subject: Subject) -> String {
        let basePrompt = "You are an expert tutor helping students with their homework. Provide clear, step-by-step solutions that help students understand the concept."
        
        switch subject {
        case .math:
            return """
            \(basePrompt)
            You are a math expert. For mathematical problems:
            - Show all work step-by-step
            - Number each step clearly (Step 1:, Step 2:, etc.)
            - Explain the reasoning behind each step
            - Include formulas used
            - Highlight the final answer
            - Mention common mistakes to avoid
            """
        case .physics:
            return """
            \(basePrompt)
            You are a physics professor. For physics problems:
            - Identify given information and unknowns
            - List relevant formulas and laws
            - Show detailed calculations with units
            - Draw diagrams if helpful (describe them)
            - Explain physical concepts involved
            - Check answer for reasonableness
            """
        case .chemistry:
            return """
            \(basePrompt)
            You are a chemistry teacher. For chemistry problems:
            - Write out chemical equations clearly
            - Balance equations step-by-step
            - Show molar calculations
            - Explain chemical concepts
            - Include safety considerations if relevant
            - Use proper chemical notation
            """
        case .biology:
            return """
            \(basePrompt)
            You are a biology expert. For biology questions:
            - Define key terms clearly
            - Explain biological processes step-by-step
            - Use proper scientific terminology
            - Relate to real-world examples
            - Include diagrams descriptions if helpful
            - Connect to broader biological concepts
            """
        case .history:
            return """
            \(basePrompt)
            You are a history professor. For history questions:
            - Provide historical context
            - Include relevant dates and figures
            - Analyze cause and effect relationships
            - Consider multiple perspectives
            - Use primary source examples when relevant
            - Structure answers with clear arguments
            """
        case .english:
            return """
            \(basePrompt)
            You are an English teacher. For English/Literature questions:
            - Analyze text with specific examples
            - Explain literary devices and techniques
            - Provide clear thesis statements
            - Structure essays with introduction, body, conclusion
            - Include relevant quotes and citations
            - Focus on grammar and style when needed
            """
        case .computerScience, .programming:
            return """
            \(basePrompt)
            You are a computer science instructor. For CS problems:
            - Explain algorithms step-by-step
            - Provide code examples when relevant
            - Analyze time/space complexity
            - Show debugging approaches
            - Explain underlying concepts
            - Use proper programming terminology
            """
        case .science:
            return """
            \(basePrompt)
            You are a general science teacher. For science questions:
            - Break down scientific concepts clearly
            - Use the scientific method approach
            - Provide real-world examples
            - Explain cause and effect
            - Include relevant formulas or laws
            - Make connections between different science fields
            """
        case .other:
            return basePrompt
        }
    }
    
    // Remove makeRequest method - no longer needed as we use backend
    
    func getCuratedResources(for question: String, subject: Subject) async throws -> [LearningResource] {
        // Use backend service for resources
        let response = try await backendService.getCuratedResources(
            question: question,
            subject: subject
        )
        
        // Convert backend resources to LearningResource
        return response.resources.map { resource in
            LearningResource(
                title: resource.title,
                type: mapResourceType(resource.type),
                url: resource.url,
                description: resource.description,
                icon: resource.icon
            )
        }
    }
    
    private func mapResourceType(_ type: String) -> LearningResource.ResourceType {
        switch type {
        case "video":
            return .video
        case "interactive":
            return .interactive
        default:
            return .article
        }
    }
    
    // Keep the static curated resources as fallback
    private func getStaticResources(for subject: Subject) -> [LearningResource] {
        var resources: [LearningResource] = []
        
        // Add subject-specific curated resources
        switch subject {
        case .math:
            resources.append(contentsOf: [
                LearningResource(
                    title: "Khan Academy - Math",
                    type: .video,
                    url: "https://www.khanacademy.org/math",
                    description: "Free video lessons and practice",
                    icon: "play.rectangle.fill"
                ),
                LearningResource(
                    title: "Wolfram Alpha",
                    type: .interactive,
                    url: "https://www.wolframalpha.com",
                    description: "Step-by-step solutions calculator",
                    icon: "function"
                ),
                LearningResource(
                    title: "Desmos Graphing Calculator",
                    type: .interactive,
                    url: "https://www.desmos.com/calculator",
                    description: "Visualize equations and functions",
                    icon: "chart.line.uptrend.xyaxis"
                )
            ])
        case .physics:
            resources.append(contentsOf: [
                LearningResource(
                    title: "Physics Classroom",
                    type: .article,
                    url: "https://www.physicsclassroom.com",
                    description: "Interactive physics tutorials",
                    icon: "atom"
                ),
                LearningResource(
                    title: "PhET Simulations",
                    type: .interactive,
                    url: "https://phet.colorado.edu",
                    description: "Interactive physics simulations",
                    icon: "waveform.circle"
                )
            ])
        case .chemistry:
            resources.append(contentsOf: [
                LearningResource(
                    title: "ChemLibreTexts",
                    type: .article,
                    url: "https://chem.libretexts.org",
                    description: "Open-access chemistry textbooks",
                    icon: "atom"
                ),
                LearningResource(
                    title: "Periodic Table",
                    type: .interactive,
                    url: "https://ptable.com",
                    description: "Interactive periodic table",
                    icon: "square.grid.3x3"
                )
            ])
        case .biology:
            resources.append(contentsOf: [
                LearningResource(
                    title: "Crash Course Biology",
                    type: .video,
                    url: "https://www.youtube.com/playlist?list=PL3EED4C1D684D3ADF",
                    description: "Engaging biology video series",
                    icon: "play.rectangle.fill"
                ),
                LearningResource(
                    title: "Biology LibreTexts",
                    type: .article,
                    url: "https://bio.libretexts.org",
                    description: "Comprehensive biology resources",
                    icon: "leaf"
                )
            ])
        case .history:
            resources.append(contentsOf: [
                LearningResource(
                    title: "History.com",
                    type: .article,
                    url: "https://www.history.com",
                    description: "Historical articles and videos",
                    icon: "book.closed"
                ),
                LearningResource(
                    title: "Crash Course History",
                    type: .video,
                    url: "https://www.youtube.com/c/crashcourse",
                    description: "World history video series",
                    icon: "play.rectangle.fill"
                )
            ])
        case .english:
            resources.append(contentsOf: [
                LearningResource(
                    title: "Purdue OWL",
                    type: .article,
                    url: "https://owl.purdue.edu",
                    description: "Writing and grammar guides",
                    icon: "pencil.circle"
                ),
                LearningResource(
                    title: "SparkNotes",
                    type: .article,
                    url: "https://www.sparknotes.com",
                    description: "Literature guides and analysis",
                    icon: "book"
                )
            ])
        case .computerScience, .programming:
            resources.append(contentsOf: [
                LearningResource(
                    title: "GeeksforGeeks",
                    type: .article,
                    url: "https://www.geeksforgeeks.org",
                    description: "Programming tutorials and examples",
                    icon: "chevron.left.forwardslash.chevron.right"
                ),
                LearningResource(
                    title: "Visualgo",
                    type: .interactive,
                    url: "https://visualgo.net",
                    description: "Algorithm visualizations",
                    icon: "chart.bar.doc.horizontal"
                )
            ])
        case .science:
            resources.append(contentsOf: [
                LearningResource(
                    title: "Khan Academy - Science",
                    type: .video,
                    url: "https://www.khanacademy.org/science",
                    description: "Free science lessons and practice",
                    icon: "play.rectangle.fill"
                ),
                LearningResource(
                    title: "Science Daily",
                    type: .article,
                    url: "https://www.sciencedaily.com",
                    description: "Latest science news and research",
                    icon: "newspaper"
                )
            ])
        case .other:
            resources.append(
                LearningResource(
                    title: "Google Scholar",
                    type: .article,
                    url: "https://scholar.google.com",
                    description: "Academic papers and resources",
                    icon: "magnifyingglass.circle"
                )
            )
        }
        
        // Add Wikipedia as a general resource
        resources.append(
            LearningResource(
                title: "Wikipedia",
                type: .article,
                url: "https://wikipedia.org",
                description: "General reference encyclopedia",
                icon: "globe"
            )
        )
        
        return resources
    }
}

enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent
    case apiKeyMissing
    case dailyLimitReached
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .noContent:
            return "No solution generated"
        case .apiKeyMissing:
            return "OpenAI API key is missing"
        case .dailyLimitReached:
            return "You've reached your daily limit. Upgrade to Premium for unlimited access!"
        }
    }
}

// Remove OpenAIResponse struct - no longer needed

struct LearningResource {
    let title: String
    let type: ResourceType
    let url: String
    let description: String
    let icon: String
    
    enum ResourceType {
        case video
        case article
        case interactive
        
        var color: Color {
            switch self {
            case .video:
                return .red
            case .article:
                return .blue
            case .interactive:
                return .purple
            }
        }
    }
}