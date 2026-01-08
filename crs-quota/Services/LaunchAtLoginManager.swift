 //
 //  LaunchAtLoginManager.swift
 //  crs-quota
 //
 
 import Foundation
 import ServiceManagement
import Combine
 
@available(macOS 13.0, *)
 class LaunchAtLoginManager: ObservableObject {
     static let shared = LaunchAtLoginManager()
     
     @Published var isEnabled: Bool {
         didSet {
             setLaunchAtLogin(isEnabled)
         }
     }
     
     private init() {
         self.isEnabled = SMAppService.mainApp.status == .enabled
     }
     
     private func setLaunchAtLogin(_ enable: Bool) {
         do {
             if enable {
                 try SMAppService.mainApp.register()
             } else {
                 try SMAppService.mainApp.unregister()
             }
         } catch {
             print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
         }
     }
     
     func refresh() {
         isEnabled = SMAppService.mainApp.status == .enabled
     }
 }
