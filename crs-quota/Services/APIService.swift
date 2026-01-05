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

    /// request timeout (s)
    private let requestTimeout: TimeInterval = 5
    /// max retry count
    private let maxRetryCount = 3
    /// retry interval (ns)
    private let retryInterval: UInt64 = 10

    private init() {}

    /// with retry
    private func withRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 1...maxRetryCount {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetryCount {
                    try await Task.sleep(nanoseconds: retryInterval * 1_000_000_000)
                }
            }
        }
        throw lastError!
    }
    
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

        return try await withRetry {
            do {
                var request = URLRequest(url: url, timeoutInterval: self.requestTimeout)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body = ["apiId": config.apiId]
                request.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.requestFailed
                }
                
                guard httpResponse.statusCode == 200 else {
                    let bodyString = String(data: data, encoding: .utf8)
                    throw APIError.httpError(statusCode: httpResponse.statusCode, body: bodyString)
                }

                let decoder = JSONDecoder()
                let result = try decoder.decode(APIStatsResponse.self, from: data)

                guard result.success, let statsData = result.data else {
                    if let message = result.message {
                        throw APIError.businessError(message)
                    }
                    throw APIError.invalidResponse
                }

                return statsData
            } catch let error as APIError {
                throw error
            } catch let error as URLError {
                if error.code == .timedOut {
                    throw APIError.timeout
                }
                throw APIError.networkError(code: error.code.rawValue)
            } catch {
                throw error
            }
        }
    }
    
    private func fetchModelStats(for config: APIConfig) async throws -> Int {
        guard let url = URL(string: config.modelStatsURL) else {
            throw APIError.invalidURL
        }

        return try await withRetry {
            do {
                var request = URLRequest(url: url, timeoutInterval: self.requestTimeout)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                struct ModelStatsRequest: Encodable {
                    let apiId: String
                    let period: String
                }

                let body = ModelStatsRequest(apiId: config.apiId, period: "daily")
                request.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.requestFailed
                }
                
                guard httpResponse.statusCode == 200 else {
                    let bodyString = String(data: data, encoding: .utf8)
                    throw APIError.httpError(statusCode: httpResponse.statusCode, body: bodyString)
                }

                let decoder = JSONDecoder()
                let result = try decoder.decode(ModelStatsResponse.self, from: data)

                guard result.success else {
                    if let message = result.message {
                        throw APIError.businessError(message)
                    }
                    throw APIError.invalidResponse
                }
                
                guard let models = result.data else {
                    return 0
                }

                return models.reduce(0) { $0 + $1.allTokens }
            } catch let error as APIError {
                throw error
            } catch let error as URLError {
                if error.code == .timedOut {
                    throw APIError.timeout
                }
                throw APIError.networkError(code: error.code.rawValue)
            } catch {
                throw error
            }
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    case httpError(statusCode: Int, body: String?)
    case networkError(code: Int)
    case timeout
    case businessError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .requestFailed:
            return "请求失败"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let statusCode, let body):
            if let body = body, !body.isEmpty {
                return body
            }
            return "HTTP 错误: \(statusCode)"
        case .networkError(let code):
            return "网络错误: \(code)"
        case .timeout:
            return "请求超时"
        case .businessError(let message):
            return message
        }
    }
}
