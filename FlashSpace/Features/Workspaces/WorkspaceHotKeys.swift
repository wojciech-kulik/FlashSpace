//
//  WorkspaceHotKeys.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class WorkspaceHotKeys {
    private let workspaceManager: WorkspaceManager
    private let workspaceRepository: WorkspaceRepository
    private let workspaceSettings: WorkspaceSettings
    private let floatingAppsSettings: FloatingAppsSettings

    init(
        workspaceManager: WorkspaceManager,
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceManager = workspaceManager
        self.workspaceRepository = workspaceRepository
        self.workspaceSettings = settingsRepository.workspaceSettings
        self.floatingAppsSettings = settingsRepository.floatingAppsSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        let hotKeys = [
            getAssignAppHotKey(for: nil),
            getUnassignAppHotKey(),
            getToggleAssignmentHotKey(),
            getRecentWorkspaceHotKey(),
            getCycleWorkspacesHotKey(next: false),
            getCycleWorkspacesHotKey(next: true),
            getFloatTheFocusedAppHotKey(),
            getUnfloatTheFocusedAppHotKey(),
            getToggleTheFocusedAppFloatingHotKey()
        ] +
            workspaceRepository.workspaces
            .flatMap { [getActivateHotKey(for: $0), getAssignAppHotKey(for: $0)] }

        return hotKeys.compactMap(\.self)
    }

    private func getActivateHotKey(for workspace: Workspace) -> (AppHotKey, () -> ())? {
        guard let shortcut = workspace.activateShortcut else { return nil }

        let action = { [weak self] in
            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return }

            self?.workspaceManager.activateWorkspace(updatedWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getAssignAppHotKey(for workspace: Workspace?) -> (AppHotKey, () -> ())? {
        let shortcut = workspace == nil
            ? workspaceSettings.assignFocusedApp
            : workspace?.assignAppShortcut

        guard let shortcut else { return nil }

        return (shortcut, { [weak self] in self?.assignApp(to: workspace) })
    }

    private func getUnassignAppHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.unassignFocusedApp else { return nil }

        return (shortcut, { [weak self] in self?.unassignApp() })
    }

    private func getToggleAssignmentHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.toggleFocusedAppAssignment else { return nil }

        let action = { [weak self] in
            guard let self, let activeApp = NSWorkspace.shared.frontmostApplication else { return }

            if workspaceRepository.workspaces.flatMap(\.apps).containsApp(activeApp) {
                unassignApp()
            } else {
                assignApp(to: nil)
            }
        }

        return (shortcut, action)
    }

    private func getCycleWorkspacesHotKey(next: Bool) -> (AppHotKey, () -> ())? {
        guard let shortcut = next
            ? workspaceSettings.switchToNextWorkspace
            : workspaceSettings.switchToPreviousWorkspace
        else { return nil }

        let action: () -> () = { [weak self] in
            self?.workspaceManager.activateWorkspace(next: next)
        }

        return (shortcut, action)
    }

    private func getRecentWorkspaceHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.switchToRecentWorkspace else { return nil }

        let action: () -> () = { [weak self] in
            self?.workspaceManager.activateRecentWorkspace()
        }

        return (shortcut, action)
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

extension WorkspaceHotKeys {
    private func assignApp(to workspace: Workspace?) {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
        guard let appName = activeApp.localizedName else { return }
        guard activeApp.activationPolicy == .regular else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashSpace."
            )
            return
        }

        guard let workspace = workspace ?? workspaceManager.activeWorkspace[activeApp.display ?? ""] else {
            Alert.showOkAlert(
                title: "Error",
                message: "No workspace is active on the current display."
            )
            return
        }

        guard let updatedWorkspace = workspaceRepository.workspaces
            .first(where: { $0.id == workspace.id }) else { return }

        activeApp.centerApp(display: updatedWorkspace.display)
        workspaceManager.assignApp(activeApp.toMacApp, to: updatedWorkspace)
        Toast.showWith(
            icon: "square.stack.3d.up",
            message: "\(appName) - Assigned To \(workspace.name)",
            textColor: .positive
        )
    }

    private func unassignApp() {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
        guard let appName = activeApp.localizedName else { return }

        if workspaceRepository.workspaces.flatMap(\.apps).containsApp(activeApp) == true {
            Toast.showWith(
                icon: "square.stack.3d.up.slash",
                message: "\(appName) - Removed From Workspaces",
                textColor: .negative
            )
        }

        workspaceRepository.deleteAppFromAllWorkspaces(app: activeApp.toMacApp)
        activeApp.hide()
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    private func floatApp() {
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
              let appName = activeApp.localizedName else { return }

        floatingAppsSettings.addFloatingAppIfNeeded(app: activeApp.toMacApp)
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
