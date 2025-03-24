//
//  FlashSpaceApp.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import SwiftUI

@main
struct FlashSpaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize workspace transition manager
        _ = WorkspaceTransitionManager.shared
    }

    var body: some Scene {
        Window("⚡ FlashSpace v\(AppConstants.version)", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        FlashSpaceMenuBar()
    }
}
