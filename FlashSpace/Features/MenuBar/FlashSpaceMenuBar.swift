//
//  FlashSpaceMenuBar.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FlashSpaceMenuBar: Scene {
    @Environment(\.openWindow) private var openWindow

    @StateObject private var workspaceManager = AppDependencies.shared.workspaceManager
    @StateObject private var settingsRepository = AppDependencies.shared.settingsRepository
    @StateObject private var profilesRepository = AppDependencies.shared.profilesRepository
    @StateObject private var workspaceRepository = AppDependencies.shared.workspaceRepository

    @State var menuBarId = UUID()
    @State var title: String?
    @State var image: Image?

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            Text("FlashSpace v\(AppConstants.version)")

            Button(settingsRepository.workspaceSettings.isPaused ? "Resume" : "Pause") {
                workspaceManager.togglePauseWorkspaceManagement()
                menuBarId = UUID()
            }
            .keyboardShortcut(settingsRepository.generalSettings.pauseResumeFlashSpace?.toKeyboardShortcut)
            .id(menuBarId)
            .onReceive(settingsRepository.workspaceSettings.$isPaused) { _ in
                menuBarId = UUID()
            }

            Divider()

            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(
                settingsRepository.generalSettings.showFlashSpace?.toKeyboardShortcut
                    ?? settingsRepository.generalSettings.toggleFlashSpace?.toKeyboardShortcut
            )

            if settingsRepository.spaceControlSettings.enableSpaceControl {
                Button("Space Control") {
                    SpaceControl.show()
                }
                .keyboardShortcut(
                    settingsRepository.spaceControlSettings.showSpaceControl?.toKeyboardShortcut
                )
            }

            Divider()

            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }.keyboardShortcut(",")

            Menu("Profiles") {
                ForEach(profilesRepository.profiles) { profile in
                    Toggle(
                        profile.name,
                        isOn: .init(
                            get: { profilesRepository.selectedProfile == profile },
                            set: {
                                if $0 { profilesRepository.selectedProfile = profile }
                            }
                        )
                    )
                }
            }.hidden(profilesRepository.profiles.count < 2)

            Menu("Workspaces") {
                ForEach(workspaceRepository.workspaces) { workspace in
                    Button {
                        if workspace.isDynamic, workspace.displays.isEmpty,
                           workspace.apps.isEmpty || workspace.openAppsOnActivation != true {
                            Toast.showWith(
                                icon: "square.stack.3d.up",
                                message: "\(workspace.name) - No Running Apps To Show",
                                textColor: .gray
                            )
                        } else {
                            workspaceManager.activateWorkspace(workspace, setFocus: true)
                        }
                    } label: {
                        Text(workspace.name)
                    }
                    .keyboardShortcut(workspace.activateShortcut?.toKeyboardShortcut)
                }
            }.hidden(workspaceRepository.workspaces.count < 2)

            Divider()

            Button("Donate") {
                SettingsNavigationManager.shared.selectedTab = "Donate"
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Project Website") {
                if let url = URL(string: "https://github.com/wojciech-kulik/FlashSpace") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Release Notes") {
                if let url = URL(string: "https://github.com/wojciech-kulik/FlashSpace/releases") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Check for Updates") {
                UpdatesManager.shared.checkForUpdates()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("q")
        } label: {
            HStack {
                if let image { image }
                if let title { Text(title) }
            }
            .onChange(of: [
                workspaceManager.activeWorkspace.values.map(\.id.uuidString).joined(separator: ","),
                (workspaceManager.activeWorkspaceDetails?.id).flatMap(\.uuidString) ?? "",
                String(settingsRepository.menuBarSettings.showMenuBarTitle),
                String(settingsRepository.menuBarSettings.showMenuBarIcon),
                String(settingsRepository.menuBarSettings.menuBarTitleUseScript),
                settingsRepository.menuBarSettings.menuBarTitleTemplate,
                settingsRepository.menuBarSettings.menuBarTitleScriptPath,
                settingsRepository.menuBarSettings.menuBarDisplayAliases

            ]) { _, _ in updateMenuBar() }
            .onAppear { updateMenuBar() }
        }
    }

    private func updateMenuBar() {
        Task { @MainActor in
            title = await MenuBarTitle.get()
            if title == nil || settingsRepository.menuBarSettings.showMenuBarIcon {
                image = Image(systemName: workspaceManager.activeWorkspaceDetails?.symbolIconName ?? .defaultIconSymbol)
            } else {
                image = nil
            }
        }
    }
}
