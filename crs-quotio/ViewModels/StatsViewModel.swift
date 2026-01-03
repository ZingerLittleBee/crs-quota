//
//  StatsViewModel.swift
//  crs-quotio
//

import Foundation
import Combine

struct StatsResult: Identifiable {
    let id: UUID
    let configName: String
    let data: APIStatsData?
    let dailyTokens: Int
    let error: String?
    let lastUpdated: Date
}

class StatsViewModel: ObservableObject {
    @Published var results: [StatsResult] = []
    @Published var isLoading = false
    @Published var lastRefreshTime: Date?
    
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    init() {
        startAutoRefresh()
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAll()
            }
        }
    }
    
    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    @MainActor
    func refreshAll() async {
        let configs = ConfigManager.shared.configs
        guard !configs.isEmpty else {
            results = []
            return
        }
        
        isLoading = true
        var newResults: [StatsResult] = []
        
        for config in configs {
            do {
                let combined = try await APIService.shared.fetchStats(for: config)
                newResults.append(StatsResult(
                    id: config.id,
                    configName: config.name,
                    data: combined.userStats,
                    dailyTokens: combined.dailyTokens,
                    error: nil,
                    lastUpdated: Date()
                ))
            } catch {
                newResults.append(StatsResult(
                    id: config.id,
                    configName: config.name,
                    data: nil,
                    dailyTokens: 0,
                    error: error.localizedDescription,
                    lastUpdated: Date()
                ))
            }
        }
        
        results = newResults
        lastRefreshTime = Date()
        isLoading = false
    }
}
