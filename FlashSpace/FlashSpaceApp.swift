//
//  FlashSpaceApp.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDependencies.shared.hotKeysManager.enableAll()

        NotificationCenter.default
            .publisher(for: .openMainWindow)
            .sink { [weak self] _ in
                self?.openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .store(in: &cancellables)

        #if DEBUG
        dismissWindow(id: "main")
        #endif
    }
}

@main
struct FlashSpaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @StateObject private var workspaceManager = AppDependencies.shared.workspaceManager
    @StateObject private var settingsRepository = AppDependencies.shared.settingsRepository

    var body: some Scene {
        Window("⚡ FlashSpace v\(AppConstants.version)", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            Text("FlashSpace v\(AppConstants.version)")

            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            if settingsRepository.enableSpaceControl {
                Button("Space Control") {
                    SpaceControl.show()
                }
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
            }.keyboardShortcut("q")
        } label: {
            HStack {
                Image(systemName: workspaceManager.activeWorkspaceDetails?.symbolIconName ?? "bolt.fill")
                if let title = MenuBarTitle.get() { Text(title) }
            }
            .id(settingsRepository.menuBarTitleTemplate)
        }
    }
}
