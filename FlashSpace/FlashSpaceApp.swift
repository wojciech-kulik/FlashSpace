//
//  FlashSpaceApp.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import SwiftUI

@main
struct FlashSpaceApp: App {
    @StateObject
    private var workspaceManager = AppDependencies.shared.workspaceManager

    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("⚡ FlashSpace v\(AppConstants.version)", id: "main") {
            MainView()
                .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra("FlashSpace", systemImage: workspaceManager.activeWorkspaceSymbolIconName ?? "bolt.fill") {
            Text("FlashSpace v\(AppConstants.version)")

            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }.keyboardShortcut(",")

            Divider()

            Button("Donate") {
                if let url = URL(string: "https://github.com/sponsors/wojciech-kulik") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Project Website") {
                if let url = URL(string: "https://github.com/wojciech-kulik/FlashSpace") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Check for Updates") {
                Task { await UpdatesManager.shared.showIfNewReleaseAvailable() }
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("q", modifiers: [.command])
        }
    }
}
