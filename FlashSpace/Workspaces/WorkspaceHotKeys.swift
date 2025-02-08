//
//  WorkspaceHotKeys.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder

final class WorkspaceHotKeys {
    private let workspaceManager: WorkspaceManager
    private let workspaceRepository: WorkspaceRepository
    private let settingsRepository: SettingsRepository

    init(
        workspaceManager: WorkspaceManager,
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceManager = workspaceManager
        self.workspaceRepository = workspaceRepository
        self.settingsRepository = settingsRepository
    }

    func getHotKeys() -> [(Shortcut, () -> ())] {
        let shortcuts = [
            getUnassignAppShortcut(),
            getRecentWorkspaceShortcut(),
            getCycleWorkspacesShortcut(next: false),
            getCycleWorkspacesShortcut(next: true),
            getFloatTheFocusedAppShortcut(),
            getUnfloatTheFocusedAppShortcut()
        ] +
            workspaceRepository.workspaces
            .flatMap { [getActivateShortcut(for: $0), getAssignAppShortcut(for: $0)] }

        return shortcuts.compactMap(\.self)
    }

    private func getActivateShortcut(for workspace: Workspace) -> (Shortcut, () -> ())? {
        guard let shortcut = workspace.activateShortcut?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return }

            self?.workspaceManager.activateWorkspace(updatedWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getAssignAppShortcut(for workspace: Workspace) -> (Shortcut, () -> ())? {
        guard let shortcut = workspace.assignAppShortcut?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
            guard let appName = activeApp.localizedName else { return }
            guard activeApp.activationPolicy == .regular else {
                showOkAlert(
                    title: appName,
                    message: "This application is an agent (runs in background) and cannot be managed by FlashSpace."
                )
                return
            }

            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return }

            activeApp.centerApp(display: updatedWorkspace.display)
            self?.workspaceManager.assignApp(activeApp.toMacApp, to: updatedWorkspace)
            showFloatingToast(
                icon: "square.stack.3d.up",
                message: "\(appName) - Assigned To \(workspace.name)",
                textColor: .positive
            )
        }

        return (shortcut, action)
    }

    private func getUnassignAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.unassignFocusedApp?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
            guard let appName = activeApp.localizedName else { return }

            if self?.workspaceRepository.workspaces.flatMap(\.apps).containsApp(activeApp) == true {
                showFloatingToast(
                    icon: "square.stack.3d.up.slash",
                    message: "\(appName) - Removed From Workspaces",
                    textColor: .negative
                )
            }

            self?.workspaceRepository.deleteAppFromAllWorkspaces(app: activeApp.toMacApp)
            activeApp.hide()
            NotificationCenter.default.post(name: .appsListChanged, object: nil)
        }

        return (shortcut, action)
    }

    private func getCycleWorkspacesShortcut(next: Bool) -> (Shortcut, () -> ())? {
        guard let shortcut =
            next
                ? settingsRepository.switchToNextWorkspace?.toShortcut()
                : settingsRepository.switchToPreviousWorkspace?.toShortcut()
        else { return nil }

        let action = { [weak self] in
            guard let self, let screen = getCursorScreen() else { return }

            var screenWorkspaces = workspaceRepository.workspaces
                .filter { $0.displayWithFallback == screen }

            if !next {
                screenWorkspaces = screenWorkspaces.reversed()
            }

            guard let activeWorkspace = workspaceManager.activeWorkspace[screen] ?? screenWorkspaces.first else { return }

            guard let workspace = screenWorkspaces
                .drop(while: { $0.id != activeWorkspace.id })
                .dropFirst()
                .first ?? screenWorkspaces.first
            else { return }

            workspaceManager.activateWorkspace(workspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getRecentWorkspaceShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.switchToRecentWorkspace?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let screen = getCursorScreen(),
                  let mostRecentWorkspace = workspaceManager.mostRecentWorkspace[screen]
            else { return }

            workspaceManager.activateWorkspace(mostRecentWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getFloatTheFocusedAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.floatTheFocusedApp?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let activeApp = NSWorkspace.shared.frontmostApplication,
                  let appName = activeApp.localizedName else { return }

            self.settingsRepository.addFloatingAppIfNeeded(app: activeApp.toMacApp)
            showFloatingToast(
                icon: "macwindow.on.rectangle",
                message: "\(appName) - Added To Floating Apps",
                textColor: .positive
            )
        }
        return (shortcut, action)
    }

    private func getUnfloatTheFocusedAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.unfloatTheFocusedApp?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let activeApp = NSWorkspace.shared.frontmostApplication,
                  let appName = activeApp.localizedName else { return }

            if settingsRepository.floatingApps?.containsApp(activeApp) == true {
                showFloatingToast(
                    icon: "macwindow",
                    message: "\(appName) - Removed From Floating Apps",
                    textColor: .negative
                )
            }

            settingsRepository.deleteFloatingApp(app: activeApp.toMacApp)

            guard let screen = activeApp.display else { return }

            if workspaceManager.activeWorkspace[screen]?.apps.containsApp(activeApp) != true {
                activeApp.hide()
            }
        }
        return (shortcut, action)
    }

    private func getCursorScreen() -> DisplayName? {
        let cursorLocation = NSEvent.mouseLocation

        return NSScreen.screens
            .first { NSMouseInRect(cursorLocation, $0.frame, false) }?
            .localizedName
    }
}
