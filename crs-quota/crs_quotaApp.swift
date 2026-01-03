//
//  crs_quotaApp.swift
//  crs-quota
//
//  Created by ZingerBee on 2026/1/3.
//

import SwiftUI

@main
struct crs_quotaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
