import Foundation
import SwiftUI

@available(iOS 17.0, *)
struct Problem: Identifiable, Codable {
    let id: UUID
    let imageData: Data?
    let questionText: String
    let solution: String
    let subject: Subject
    let createdAt: Date
    let difficulty: Difficulty
    
    init(id: UUID = UUID(), imageData: Data? = nil, questionText: String, solution: String = "", subject: Subject, createdAt: Date = Date(), difficulty: Difficulty = .medium) {
        self.id = id
        self.imageData = imageData
        self.questionText = questionText
        self.solution = solution
        self.subject = subject
        self.createdAt = createdAt
        self.difficulty = difficulty
    }
}

@available(iOS 17.0, *)
enum Subject: String, CaseIterable, Codable {
    case math = "Mathematics"
    case science = "Science"
    case physics = "Physics"
    case chemistry = "Chemistry"
    case biology = "Biology"
    case english = "English"
    case history = "History"
    case programming = "Programming"
    case computerScience = "Computer Science"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .math: return "function"
        case .science: return "atom"
        case .physics: return "bolt.fill"
        case .chemistry: return "flask.fill"
        case .biology: return "leaf.fill"
        case .english: return "text.book.closed"
        case .history: return "clock.arrow.circlepath"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        case .computerScience: return "desktopcomputer"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .math: return .blue
        case .science: return .green
        case .physics: return .indigo
        case .chemistry: return .purple
        case .biology: return .mint
        case .english: return .orange
        case .history: return .brown
        case .programming: return .purple
        case .computerScience: return .cyan
        case .other: return .gray
        }
    }
}

@available(iOS 17.0, *)
enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}