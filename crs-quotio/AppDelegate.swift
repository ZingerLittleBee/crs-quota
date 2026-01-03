//
//  AppDelegate.swift
//  crs-quotio
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    
    let viewModel = StatsViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "CRS Quota")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 500)
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
