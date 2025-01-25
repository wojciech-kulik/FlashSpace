//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import ShortcutRecorder

typealias DisplayName = String

final class WorkspaceManager: ObservableObject {
    @Published private(set) var activeWorkspaceSymbolIconName: String?

    private(set) var activeWorkspace: [DisplayName: Workspace] = [:]
    private(set) var lastWorkspaceActivation = Date.distantPast

    private var cancellables = Set<AnyCancellable>()
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    private let workspaceRepository: WorkspaceRepository
    private let settingsRepository: SettingsRepository

    init(
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceRepository = workspaceRepository
        self.settingsRepository = settingsRepository

        PermissionsManager.shared.askForAccessibilityPermissions()

        hideAgainSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] in self?.hideApps(in: $0) }
            .store(in: &cancellables)
    }

    private func showApps(in workspace: Workspace, setFocus: Bool) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let appsToShow = regularApps
            .filter { workspace.apps.contains($0.localizedName ?? "") }

        for app in appsToShow {
            print("SHOW: \(app.localizedName ?? "")")
            app.unhide()
        }

        if setFocus {
            let appToFocus = appsToShow.first { $0.localizedName == workspace.appToFocus }
            let lastApp = appsToShow.first { $0.localizedName == workspace.apps.last }
            let toFocus = appToFocus ?? lastApp
            toFocus?.focus()
            centerCursorIfNeeded(in: toFocus?.getFrame())
        }
    }

    private func hideApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let hasMoreScreens = NSScreen.screens.count > 1
        let appsToHide = regularApps
            .filter { !workspace.apps.contains($0.localizedName ?? "") && !$0.isHidden }
            .filter { !hasMoreScreens || $0.getFrame()?.getDisplay() == workspace.display }

        for app in appsToHide {
            print("HIDE: \(app.localizedName ?? "")")
            app.hide()
        }
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard settingsRepository.centerCursorOnWorkspaceChange, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }
}

extension WorkspaceManager {
    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        print("\n\nWORKSPACE: \(workspace.name)")
        print("----")

        Integrations.runOnActivateIfNeeded(workspace: workspace)

        lastWorkspaceActivation = Date()
        activeWorkspace[workspace.display] = workspace
        activeWorkspaceSymbolIconName = workspace.symbolIconName
        showApps(in: workspace, setFocus: setFocus)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)
    }

    func assignApp(_ app: String, to workspace: Workspace) {
        workspaceRepository.deleteAppFromAllWorkspaces(app: app)
        workspaceRepository.addApp(to: workspace.id, app: app)

        guard let updatedWorkspace = workspaceRepository.workspaces
            .first(where: { $0.id == workspace.id }) else { return }

        activateWorkspace(updatedWorkspace, setFocus: false)
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }
}

// MARK: - Shortcuts
extension WorkspaceManager {
    func getHotKeys() -> [(Shortcut, () -> ())] {
        let shortcuts = [
            getUnassignAppShortcut(),
            getCycleWorkspacesShortcut(next: false),
            getCycleWorkspacesShortcut(next: true)
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

            self?.activateWorkspace(updatedWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getAssignAppShortcut(for workspace: Workspace) -> (Shortcut, () -> ())? {
        guard let shortcut = workspace.assignAppShortcut?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
            guard let appName = activeApp.localizedName else { return }
            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return }

            activeApp.centerApp(display: updatedWorkspace.display)
            self?.assignApp(appName, to: updatedWorkspace)
        }

        return (shortcut, action)
    }

    private func getUnassignAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.unassignFocusedApp?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
            guard let appName = activeApp.localizedName else { return }

            self?.workspaceRepository.deleteAppFromAllWorkspaces(app: appName)
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

            let hasMoreScreens = NSScreen.screens.count > 1
            var screenWorkspaces = workspaceRepository.workspaces
                .filter { !hasMoreScreens || $0.display == screen }

            if !next {
                screenWorkspaces = screenWorkspaces.reversed()
            }

            guard let activeWorkspace = activeWorkspace[screen] ?? screenWorkspaces.first else { return }

            guard let workspace = screenWorkspaces
                .drop(while: { $0.id != activeWorkspace.id })
                .dropFirst()
                .first ?? screenWorkspaces.first
            else { return }

            activateWorkspace(workspace, setFocus: true)
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
