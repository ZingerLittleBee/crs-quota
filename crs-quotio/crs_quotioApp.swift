//
//  crs_quotioApp.swift
//  crs-quotio
//
//  Created by ZingerBee on 2026/1/3.
//

import SwiftUI

@main
struct crs_quotioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
