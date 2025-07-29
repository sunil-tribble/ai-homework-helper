import SwiftUI
import Vision
import VisionKit
import PhotosUI

@MainActor
@available(iOS 17.0, *)
class ScannerViewModel: ObservableObject {
    @Published var scannedImage: UIImage?
    @Published var recognizedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var showingSolution: Bool = false
    @Published var currentProblem: Problem?
    @Published var error: String?
    @Published var selectedSubject: Subject = .math
    
    private let openAIService = OpenAIService()
    private let problemStorage = ProblemStorage.shared
    
    func processImage(_ image: UIImage) {
        self.scannedImage = image
        self.isProcessing = true
        self.error = nil
        
        Task {
            do {
                // Extract text from image
                let text = try await extractText(from: image)
                self.recognizedText = text
                
                // Get solution from OpenAI
                let solution = try await openAIService.getSolution(
                    for: text,
                    subject: selectedSubject,
                    imageData: image.jpegData(compressionQuality: 0.8)
                )
                
                // Create and save problem
                let problem = Problem(
                    imageData: image.jpegData(compressionQuality: 0.8),
                    questionText: text,
                    solution: solution,
                    subject: selectedSubject
                )
                
                self.currentProblem = problem
                problemStorage.saveProblem(problem)
                
                self.showingSolution = true
            } catch {
                self.error = error.localizedDescription
            }
            
            self.isProcessing = false
        }
    }
    
    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ScannerError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                
                if fullText.isEmpty {
                    continuation.resume(throwing: ScannerError.noTextFound)
                } else {
                    continuation.resume(returning: fullText)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func processTextInput(_ text: String) {
        self.recognizedText = text
        self.isProcessing = true
        self.error = nil
        
        Task {
            do {
                // Get solution from OpenAI
                let solution = try await openAIService.getSolution(
                    for: text,
                    subject: selectedSubject,
                    imageData: nil
                )
                
                // Create and save problem
                let problem = Problem(
                    imageData: nil,
                    questionText: text,
                    solution: solution,
                    subject: selectedSubject
                )
                
                self.currentProblem = problem
                problemStorage.saveProblem(problem)
                
                self.showingSolution = true
            } catch {
                self.error = error.localizedDescription
            }
            
            self.isProcessing = false
        }
    }
    
    func reset() {
        scannedImage = nil
        recognizedText = ""
        currentProblem = nil
        error = nil
        showingSolution = false
    }
}

enum ScannerError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}