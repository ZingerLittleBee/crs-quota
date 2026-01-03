//
//  MenuBarView.swift
//  crs-quotio
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: StatsViewModel
    @ObservedObject var configManager = ConfigManager.shared
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("CRS Quota Monitor")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if configManager.configs.isEmpty {
                emptyStateView
            } else if viewModel.results.isEmpty {
                loadingStateView
            } else {
                statsListView
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 380)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.2")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No API configured")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Click Settings to add an API")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var statsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.results) { result in
                    StatsCardView(result: result)
                }
            }
            .padding(8)
        }
        .frame(height: 500)
    }
    
    private var footerView: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: {
                    Task {
                        await viewModel.refreshAll()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Now")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                Button(action: {
                    showSettings = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            if let lastRefresh = viewModel.lastRefreshTime {
                Text("Last updated: \(lastRefresh, formatter: timeFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 6)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct StatsCardView: View {
    let result: StatsResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with name and status
            HStack {
                Text(result.configName)
                    .font(.headline)
                Spacer()
                if result.error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                } else if result.data?.isActive == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            if let error = result.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let data = result.data {
                statsContent(data: data, dailyTokens: result.dailyTokens)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func statsContent(data: APIStatsData, dailyTokens: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // User name
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(data.name)
                    .font(.subheadline)
            }
            
            Divider()
            
            // Cost info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text("Total Cost")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(data.usage.total.formattedCost)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: "$%.2f", data.limits.currentDailyCost))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
            }
            
            // Daily limit progress
            if data.limits.dailyCostLimit > 0 {
                let progress = min(data.limits.currentDailyCost / data.limits.dailyCostLimit, 1.0)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Daily Limit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f / $%.0f", data.limits.currentDailyCost, data.limits.dailyCostLimit))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: progress)
                        .tint(progress > 0.8 ? .red : (progress > 0.5 ? .orange : .green))
                }
            }
            
            Divider()
            
            // Tokens
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .foregroundColor(.cyan)
                        Text("Total Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(formatNumber(data.usage.total.allTokens))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Today Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(formatNumber(dailyTokens))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Concurrency
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.indigo)
                Text("Concurrency: \(data.limits.concurrencyLimit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Expiry info
            if let expiresAt = parseDate(data.expiresAt) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.red)
                        Text("Expires: \(expiresAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(isExpiringSoon(expiresAt) ? .red : .secondary)
                    }
                    Spacer()
                    Text(remainingDaysText(expiresAt))
                        .font(.caption)
                        .foregroundColor(isExpiringSoon(expiresAt) ? .red : .secondary)
                }
            }
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000_000 {
            return String(format: "%.1fB", Double(num) / 1_000_000_000)
        } else if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysUntilExpiry <= 7
    }
    
    private func remainingDaysText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
}
