//
//  AppDelegate.swift
//  crs-quota
//

import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    let viewModel = StatsViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            updateStatusBarIcon(button: button, percentages: [])
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Observe viewModel changes to update status bar
        viewModel.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.updateStatusBarFromResults(results)
            }
            .store(in: &cancellables)
        
        // Observe config changes to auto refresh
        ConfigManager.shared.$configs
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.viewModel.refreshAll()
                }
            }
            .store(in: &cancellables)
        
        // Create popover
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(
                viewModel: viewModel,
                showSettings: Binding(
                    get: { false },
                    set: { [weak self] show in
                        if show {
                            self?.showSettings()
                        }
                    }
                )
            )
        )
        
        // Initial refresh
        Task {
            await viewModel.refreshAll()
        }
    }
    
    private func updateStatusBarFromResults(_ results: [StatsResult]) {
        guard let button = statusItem.button else { return }
        
        // Get configs that should show in menu bar
        let menuBarConfigs = ConfigManager.shared.configs.filter { $0.showInMenuBar }
        let menuBarConfigIds = Set(menuBarConfigs.map { $0.id })
        
        // Collect percentages for each config
        var percentages: [(percentage: Double, name: String)] = []
        
        for result in results {
            guard menuBarConfigIds.contains(result.id) else { continue }
            if let data = result.data, data.limits.dailyCostLimit > 0 {
                let percentage = min(data.limits.currentDailyCost / data.limits.dailyCostLimit, 1.0)
                percentages.append((percentage, result.configName))
            }
        }
        
        updateStatusBarIcon(button: button, percentages: percentages)
    }
    
    private func updateStatusBarIcon(button: NSStatusBarButton, percentages: [(percentage: Double, name: String)]) {
        guard !percentages.isEmpty else {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "CRS Quota")
            button.title = ""
            return
        }
        
        let attributedString = NSMutableAttributedString()
        
        for (index, item) in percentages.enumerated() {
            let percentInt = Int(item.percentage * 100)
            
            // Choose color based on percentage
            let color: NSColor
            if item.percentage > 0.8 {
                color = .systemRed
            } else if item.percentage > 0.5 {
                color = .systemOrange
            } else {
                color = .systemGreen
            }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: color
            ]
            
            attributedString.append(NSAttributedString(string: "\(percentInt)%", attributes: attributes))
            
            // Add separator between percentages
            if index < percentages.count - 1 {
                let separatorAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
                attributedString.append(NSAttributedString(string: " | ", attributes: separatorAttributes))
            }
        }
        
        button.attributedTitle = attributedString
        button.image = nil
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Update popover content
            popover.contentViewController = NSHostingController(
                rootView: MenuBarView(
                    viewModel: viewModel,
                    showSettings: Binding(
                        get: { false },
                        set: { [weak self] show in
                            if show {
                                self?.popover.performClose(nil)
                                self?.showSettings()
                            }
                        }
                    )
                )
            )
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
