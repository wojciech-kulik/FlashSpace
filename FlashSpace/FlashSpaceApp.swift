//
//  FlashSpaceApp.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import SwiftUI

@main
struct FlashSpaceApp: App {
    @Environment(\.openWindow) private var openWindow

    var version: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }

        return version
    }

    var body: some Scene {
        Window("⚡ FlashSpace v\(version)", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra("FlashSpace", systemImage: "bolt.fill") {
            Text("FlashSpace v\(version)")

            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

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
                if let url = URL(string: "https://github.com/wojciech-kulik/FlashSpace/releases") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("q", modifiers: [.command])
        }
    }
}
