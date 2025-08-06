import Foundation
import SwiftUI

// MARK: - Backend Service

class BackendService: ObservableObject {
    static let shared = BackendService()
    
    // Backend URL from Config
    private let baseURL = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? Config.backendURL
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private var sessionToken: String? {
        get { UserDefaults.standard.string(forKey: "sessionToken") }
        set { UserDefaults.standard.set(newValue, forKey: "sessionToken") }
    }
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        
        // Check if we have a stored session
        if sessionToken != nil {
            Task {
                await validateSession()
            }
        }
    }
    
    // MARK: - Authentication
    
    func deviceLogin() async throws -> AuthResponse {
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString }
        let deviceModel = await MainActor.run { UIDevice.current.model }
        let osVersion = await MainActor.run { UIDevice.current.systemVersion }
        
        let body = DeviceLoginRequest(
            deviceId: deviceId,
            deviceModel: deviceModel,
            osVersion: osVersion
        )
        
        let response: AuthResponse = try await request(
            endpoint: "/api/v1/auth/device",
            method: "POST",
            body: body
        )
        
        sessionToken = response.sessionToken
        currentUser = response.user
        isAuthenticated = true
        
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        
        let response: AuthResponse = try await request(
            endpoint: "/api/v1/auth/login",
            method: "POST",
            body: body
        )
        
        sessionToken = response.sessionToken
        currentUser = response.user
        isAuthenticated = true
        
        return response
    }
    
    func logout() async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/api/v1/auth/logout",
            method: "POST",
            authenticated: true
        )
        
        sessionToken = nil
        currentUser = nil
        isAuthenticated = false
    }
    
    func validateSession() async {
        do {
            let response: MeResponse = try await request(
                endpoint: "/api/v1/users/me",
                method: "GET",
                authenticated: true
            )
            
            currentUser = response.user
            isAuthenticated = true
        } catch {
            sessionToken = nil
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - Homework
    
    func solveProblem(question: String, subject: Subject, imageData: Data? = nil) async throws -> SolutionResponse {
        var body = SolveProblemRequest(
            question: question,
            subject: subject.rawValue
        )
        
        if let imageData = imageData {
            body.imageData = imageData.base64EncodedString()
        }
        
        return try await request(
            endpoint: "/api/v1/homework/solve",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    func getProblemHistory(limit: Int = 20, offset: Int = 0) async throws -> HistoryResponse {
        return try await request(
            endpoint: "/api/v1/homework/history?limit=\(limit)&offset=\(offset)",
            method: "GET",
            authenticated: true
        )
    }
    
    func rateProblem(problemId: String, rating: Int, wasHelpful: Bool) async throws {
        let body = RateProblemRequest(rating: rating, wasHelpful: wasHelpful)
        
        let _: EmptyResponse = try await request(
            endpoint: "/api/v1/homework/problem/\(problemId)/rate",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    func getCuratedResources(question: String, subject: Subject) async throws -> ResourcesResponse {
        let body = ResourcesRequest(question: question, subject: subject.rawValue)
        
        return try await request(
            endpoint: "/api/v1/homework/resources",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    // MARK: - Subscription
    
    func processSubscription(receipt: String, productId: String, transactionId: String, originalTransactionId: String, purchaseDate: Date, expiryDate: Date) async throws -> SubscriptionResponse {
        let body = ProcessSubscriptionRequest(
            receipt: receipt,
            productId: productId,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            purchaseDate: ISO8601DateFormatter().string(from: purchaseDate),
            expiryDate: ISO8601DateFormatter().string(from: expiryDate)
        )
        
        return try await request(
            endpoint: "/api/v1/subscription/process",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        return try await request(
            endpoint: "/api/v1/subscription/status",
            method: "GET",
            authenticated: true
        )
    }
    
    // MARK: - Private Methods
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        authenticated: Bool = false
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            return try decoder.decode(T.self, from: data)
        }
        
        // Try to parse error response
        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            throw BackendError.serverError(message: errorResponse.error, upgradeRequired: errorResponse.upgradeRequired ?? false)
        }
        
        throw BackendError.httpError(statusCode: httpResponse.statusCode)
    }
}

// MARK: - Data Models

struct User: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let subscriptionStatus: String
    let subscriptionType: String?
    let dailySolvesUsed: Int
    let totalSolves: Int
    let points: Int
    let level: Int
    let badges: [String]
}

struct AuthResponse: Codable {
    let sessionToken: String?
    let user: User
}

struct MeResponse: Codable {
    let user: User
}

struct DeviceLoginRequest: Codable {
    let deviceId: String
    let deviceModel: String?
    let osVersion: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SolveProblemRequest: Codable {
    let question: String
    let subject: String
    var imageData: String?
    var difficulty: String?
}

struct SolutionResponse: Codable {
    let problemId: String
    let solution: String
    let tokensUsed: Int
    let dailySolvesRemaining: Int
    let streak: Int?
    let points: Int?
}

struct HistoryResponse: Codable {
    let problems: [Problem]
    let total: Int
    let limit: Int
    let offset: Int
}

struct RateProblemRequest: Codable {
    let rating: Int
    let wasHelpful: Bool
}

struct ResourcesRequest: Codable {
    let question: String
    let subject: String
}

struct ResourcesResponse: Codable {
    let resources: [BackendResource]
}

struct BackendResource: Codable {
    let title: String
    let type: String
    let url: String
    let description: String
    let icon: String
}

struct ProcessSubscriptionRequest: Codable {
    let receipt: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let purchaseDate: String
    let expiryDate: String
}

struct SubscriptionResponse: Codable {
    let success: Bool
    let subscriptionStatus: String
    let expiryDate: String
}

struct SubscriptionStatusResponse: Codable {
    let subscriptionStatus: String
    let subscriptionType: String?
    let subscriptionExpiry: Date?
    let dailySolvesUsed: Int
    let dailySolvesRemaining: Int
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
    let upgradeRequired: Bool?
}

struct EmptyResponse: Codable {}

// MARK: - Errors

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case serverError(message: String, upgradeRequired: Bool)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "Server error (code: \(statusCode))"
        case .serverError(let message, _):
            return message
        }
    }
    
    var requiresUpgrade: Bool {
        if case .serverError(_, let upgradeRequired) = self {
            return upgradeRequired
        }
        return false
    }
}