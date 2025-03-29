//
//  FloatingAppsHotKeys.swift
//
//  Created by Wojciech Kulik on 16/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class FloatingAppsHotKeys {
    private let workspaceManager: WorkspaceManager
    private let floatingAppsSettings: FloatingAppsSettings

    init(
        workspaceManager: WorkspaceManager,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceManager = workspaceManager
        self.floatingAppsSettings = settingsRepository.floatingAppsSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        let hotKeys = [
            getFloatTheFocusedAppHotKey(),
            getUnfloatTheFocusedAppHotKey(),
            getToggleTheFocusedAppFloatingHotKey()
        ]

        return hotKeys.compactMap(\.self)
    }

    private func getFloatTheFocusedAppHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = floatingAppsSettings.floatTheFocusedApp else { return nil }

        return (shortcut, { [weak self] in self?.floatApp() })
    }

    private func getUnfloatTheFocusedAppHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = floatingAppsSettings.unfloatTheFocusedApp else { return nil }

        return (shortcut, { [weak self] in self?.unfloatApp() })
    }

    private func getToggleTheFocusedAppFloatingHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = floatingAppsSettings.toggleTheFocusedAppFloating else { return nil }

        let action = { [weak self] in
            guard let self, let activeApp = NSWorkspace.shared.frontmostApplication else { return }

            if floatingAppsSettings.floatingApps.containsApp(activeApp) {
                unfloatApp()
            } else {
                floatApp()
            }
        }
        return (shortcut, action)
    }
}

extension FloatingAppsHotKeys {
    private func floatApp() {
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
              let appName = activeApp.localizedName else { return }

        floatingAppsSettings.addFloatingAppIfNeeded(app: activeApp.toMacApp)

        // Update the lastFocusedApp history for all workspaces on the same display
        if let display = activeApp.display {
            for workspace in workspaceManager.activeWorkspace.values where workspace.displayWithFallback == display {
                workspaceManager.updateLastFocusedApp(activeApp.toMacApp, in: workspace)
            }
        }

        Toast.showWith(
            icon: "macwindow.on.rectangle",
            message: "\(appName) - Added To Floating Apps",
            textColor: .positive
        )
    }

    private func unfloatApp() {
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
              let appName = activeApp.localizedName else { return }

        if floatingAppsSettings.floatingApps.containsApp(activeApp) {
            Toast.showWith(
                icon: "macwindow",
                message: "\(appName) - Removed From Floating Apps",
                textColor: .negative
            )
        }

        floatingAppsSettings.deleteFloatingApp(app: activeApp.toMacApp)

        guard let screen = activeApp.display else { return }

        if workspaceManager.activeWorkspace[screen]?.apps.containsApp(activeApp) != true {
            activeApp.hide()
        }
    }
}
