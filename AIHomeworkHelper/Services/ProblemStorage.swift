import Foundation
import SwiftUI

class ProblemStorage: ObservableObject {
    static let shared = ProblemStorage()
    
    @Published var problems: [Problem] = []
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "savedProblems"
    
    init() {
        loadProblems()
    }
    
    func saveProblem(_ problem: Problem) {
        problems.insert(problem, at: 0)
        saveToUserDefaults()
    }
    
    func deleteProblem(_ problem: Problem) {
        problems.removeAll { $0.id == problem.id }
        saveToUserDefaults()
    }
    
    func deleteProblems(at offsets: IndexSet) {
        problems.remove(atOffsets: offsets)
        saveToUserDefaults()
    }
    
    func getProblemsBySubject(_ subject: Subject) -> [Problem] {
        problems.filter { $0.subject == subject }
    }
    
    func getRecentProblems(limit: Int = 10) -> [Problem] {
        Array(problems.prefix(limit))
    }
    
    private func loadProblems() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decodedProblems = try? JSONDecoder().decode([Problem].self, from: data) else {
            return
        }
        problems = decodedProblems
    }
    
    private func saveToUserDefaults() {
        guard let encoded = try? JSONEncoder().encode(problems) else { return }
        userDefaults.set(encoded, forKey: storageKey)
    }
}