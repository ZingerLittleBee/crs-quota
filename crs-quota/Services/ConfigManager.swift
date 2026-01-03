//
//  ConfigManager.swift
//  crs-quota
//

import Foundation
import SwiftUI
import Combine

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var configs: [APIConfig] = []
    
    private let configsKey = "api_configs"
    
    private init() {
        loadConfigs()
    }
    
    func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: configsKey),
           let configs = try? JSONDecoder().decode([APIConfig].self, from: data) {
            self.configs = configs
        }
    }
    
    func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: configsKey)
        }
    }
    
    func addConfig(_ config: APIConfig) {
        configs.append(config)
        saveConfigs()
    }
    
    func removeConfig(at offsets: IndexSet) {
        configs.remove(atOffsets: offsets)
        saveConfigs()
    }
    
    func removeConfig(id: UUID) {
        configs.removeAll { $0.id == id }
        saveConfigs()
    }
    
    func updateConfig(_ config: APIConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            saveConfigs()
        }
    }
}
