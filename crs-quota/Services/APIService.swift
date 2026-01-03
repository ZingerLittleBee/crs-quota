//
//  APIService.swift
//  crs-quota
//

import Foundation

struct CombinedStats {
    let userStats: APIStatsData
    let dailyTokens: Int
}

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    func fetchStats(for config: APIConfig) async throws -> CombinedStats {
        async let userStats = fetchUserStats(for: config)
        async let modelStats = fetchModelStats(for: config)
        
        let stats = try await userStats
        let dailyTokens = try await modelStats
        
        return CombinedStats(userStats: stats, dailyTokens: dailyTokens)
    }
    
    private func fetchUserStats(for config: APIConfig) async throws -> APIStatsData {
        guard let url = URL(string: config.statsURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["apiId": config.apiId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(APIStatsResponse.self, from: data)
        
        guard result.success, let statsData = result.data else {
            throw APIError.invalidResponse
        }
        
        return statsData
    }
    
    private func fetchModelStats(for config: APIConfig) async throws -> Int {
        guard let url = URL(string: config.modelStatsURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct ModelStatsRequest: Encodable {
            let apiId: String
            let period: String
        }
        
        let body = ModelStatsRequest(apiId: config.apiId, period: "daily")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(ModelStatsResponse.self, from: data)
        
        guard result.success, let models = result.data else {
            return 0
        }
        
        return models.reduce(0) { $0 + $1.allTokens }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}
