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

    var body: some Scene {
        Window("FlashSpace", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra("FlashSpace", systemImage: "bolt.fill") {
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

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("q", modifiers: [.command])
        }
    }
}
