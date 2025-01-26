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
    private(set) var mostRecentWorkspace: [DisplayName: Workspace] = [:]

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
        let workspaceApps = Set(workspace.apps + (settingsRepository.floatingApps ?? []))
        let appsToShow = regularApps
            .filter { workspaceApps.contains($0.localizedName ?? "") }

        for app in appsToShow {
            print("SHOW: \(app.localizedName ?? "")")
            app.raise()
        }

        if setFocus {
            let appToFocus = appsToShow.first { $0.localizedName == workspace.appToFocus }
            let lastApp = appsToShow.first { $0.localizedName == workspace.apps.last }
            let toFocus = appToFocus ?? lastApp
            toFocus?.activate()
            centerCursorIfNeeded(in: toFocus?.getFrame())
        }
    }

    private func hideApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let hasMoreScreens = NSScreen.screens.count > 1
        let workspaceApps = Set(workspace.apps + (settingsRepository.floatingApps ?? []))
        let appsToHide = regularApps
            .filter { !workspaceApps.contains($0.localizedName ?? "") && !$0.isHidden }
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

        // Save the most recent workspace if it's not the current one
        if activeWorkspace[workspace.display]?.id != workspace.id {
            mostRecentWorkspace[workspace.display] = activeWorkspace[workspace.display]
        }

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
            getRecentWorkspaceShortcut(),
            getCycleWorkspacesShortcut(next: false),
            getCycleWorkspacesShortcut(next: true),
            getFlootTheFocusedAppShortcut(),
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

            self?.activateWorkspace(updatedWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getAssignAppShortcut(for workspace: Workspace) -> (Shortcut, () -> ())? {
        guard let shortcut = workspace.assignAppShortcut?.toShortcut() else { return nil }

        let action = { [weak self] in
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
            guard let appName = activeApp.localizedName else { return }
            guard activeApp.bundleURL?.bundle?.isAgent != true else {
                showOkAlert(
                    title: appName,
                    message: "This application is an agent (runs in background) and cannot be managed by FlashSpace."
                )
                return
            }

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
            guard let self else { return }

            let cursorScreenWorkspaces = cursorScreenWorkspaces
            guard let screen = cursorScreenWorkspaces.screen else { return }
            var screenWorkspaces = cursorScreenWorkspaces.workspaces

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

    private func getRecentWorkspaceShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.switchToRecentWorkspace?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let screen = getCursorScreen(),
                  let mostRecentWorkspace = mostRecentWorkspace[screen]
            else { return }

            activateWorkspace(mostRecentWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getFlootTheFocusedAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.floatTheFocusedApp?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let activeApp = NSWorkspace.shared.frontmostApplication,
                  let appName = activeApp.localizedName else { return }

            self.settingsRepository.addFloatingAppIfNeeded(app: appName)
        }
        return (shortcut, action)
    }

    private func getUnfloatTheFocusedAppShortcut() -> (Shortcut, () -> ())? {
        guard let shortcut = settingsRepository.unfloatTheFocusedApp?.toShortcut() else { return nil }
        let action = { [weak self] in
            guard let self,
                  let activeApp = NSWorkspace.shared.frontmostApplication,
                  let appName = activeApp.localizedName else { return }

            self.settingsRepository.deleteFloatingApp(app: appName)

            let cursorScreenWorkspaces = cursorScreenWorkspaces
            guard let screen = cursorScreenWorkspaces.screen else { return }
            if activeWorkspace[screen]?.apps.contains(appName) != true {
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

    private var cursorScreenWorkspaces: (screen: DisplayName?, workspaces: [Workspace]) {
        let screen = getCursorScreen()
        let hasMoreScreens = NSScreen.screens.count > 1
        return (
            screen,
            workspaceRepository.workspaces
                .filter { !hasMoreScreens || $0.display == screen }
        )
    }
}
