//
//  SettingsView.swift
//  crs-quotio
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddSheet = false
    @State private var editingConfig: APIConfig?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("API Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            // Config List
            if configManager.configs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No API endpoints configured")
                        .foregroundColor(.secondary)
                    Button("Add API Endpoint") {
                        showAddSheet = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(configManager.configs) { config in
                        ConfigRowView(config: config, onEdit: {
                            editingConfig = config
                        }, onDelete: {
                            configManager.removeConfig(id: config.id)
                        })
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(configManager.configs.count) endpoint(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
        .sheet(isPresented: $showAddSheet) {
            ConfigEditView(config: nil) { newConfig in
                configManager.addConfig(newConfig)
            }
        }
        .sheet(item: $editingConfig) { config in
            ConfigEditView(config: config) { updatedConfig in
                configManager.updateConfig(updatedConfig)
            }
        }
    }
}

struct ConfigRowView: View {
    let config: APIConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(config.name)
                        .font(.headline)
                    if config.showInMenuBar {
                        Image(systemName: "menubar.rectangle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                Text(config.baseURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text("API ID: \(config.apiId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct ConfigEditView: View {
    let config: APIConfig?
    let onSave: (APIConfig) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var baseURL: String = ""
    @State private var apiId: String = ""
    @State private var showInMenuBar: Bool = true
    
    var isValid: Bool {
        !name.isEmpty && !baseURL.isEmpty && !apiId.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(config == nil ? "Add API Endpoint" : "Edit API Endpoint")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Base URL", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                
                TextField("API ID", text: $apiId)
                    .textFieldStyle(.roundedBorder)
                
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                    .toggleStyle(.checkbox)
                
                if !baseURL.isEmpty && !apiId.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full URL Preview:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(baseURL)/apiStats/api/user-stats")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                        Text("Body: {\"apiId\": \"\(apiId)\"}")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(config == nil ? "Add" : "Save") {
                    var newConfig = config ?? APIConfig(name: "", baseURL: "", apiId: "")
                    newConfig.name = name
                    newConfig.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    newConfig.apiId = apiId
                    newConfig.showInMenuBar = showInMenuBar
                    onSave(newConfig)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .onAppear {
            if let config = config {
                name = config.name
                baseURL = config.baseURL
                apiId = config.apiId
                showInMenuBar = config.showInMenuBar
            }
        }
    }
}

#Preview {
    SettingsView()
}
