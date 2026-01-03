//
//  APIConfig.swift
//  crs-quotio
//

import Foundation

struct APIConfig: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var baseURL: String
    var apiId: String
    var showInMenuBar: Bool = true
    
    var statsURL: String {
        "\(baseURL)/apiStats/api/user-stats"
    }
    
    var modelStatsURL: String {
        "\(baseURL)/apiStats/api/user-model-stats"
    }
}

struct APIStatsResponse: Codable {
    let success: Bool
    let data: APIStatsData?
}

struct APIStatsData: Codable {
    let id: String
    let name: String
    let description: String?
    let isActive: Bool
    let createdAt: String
    let expiresAt: String
    let expirationMode: String
    let isActivated: Bool
    let activationDays: Int?
    let activatedAt: String?
    let permissions: String?
    let usage: UsageData
    let limits: LimitsData
}

struct UsageData: Codable {
    let total: TotalUsage
}

struct TotalUsage: Codable {
    let tokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreateTokens: Int
    let cacheReadTokens: Int
    let allTokens: Int
    let requests: Int
    let cost: Double
    let formattedCost: String
}

struct LimitsData: Codable {
    let tokenLimit: Int
    let concurrencyLimit: Int
    let rateLimitWindow: Int
    let rateLimitRequests: Int
    let rateLimitCost: Int
    let dailyCostLimit: Double
    let totalCostLimit: Double
    let weeklyOpusCostLimit: Double
    let currentWindowRequests: Int
    let currentWindowTokens: Int
    let currentWindowCost: Double
    let currentDailyCost: Double
    let currentTotalCost: Double
    let weeklyOpusCost: Double
}

struct ModelStatsResponse: Codable {
    let success: Bool
    let data: [ModelStatsData]?
    let period: String?
}

struct ModelStatsData: Codable {
    let model: String
    let requests: Int
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreateTokens: Int
    let cacheReadTokens: Int
    let allTokens: Int
}
