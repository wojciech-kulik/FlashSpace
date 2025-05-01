//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

typealias DisplayName = String

struct ActiveWorkspace {
    let id: WorkspaceID
    let name: String
    let number: String?
    let symbolIconName: String?
    let display: DisplayName
}

final class WorkspaceManager: ObservableObject {
    @Published private(set) var activeWorkspaceDetails: ActiveWorkspace?

    private(set) var lastFocusedApp: [WorkspaceID: MacApp] = [:]
    private(set) var activeWorkspace: [DisplayName: Workspace] = [:]
    private(set) var mostRecentWorkspace: [DisplayName: Workspace] = [:]
    private(set) var lastWorkspaceActivation = Date.distantPast

    private var cancellables = Set<AnyCancellable>()
    private var observeFocusCancellable: AnyCancellable?
    private var lastFocusedFloatingApp: [DisplayName: MacApp] = [:]
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    private let workspaceRepository: WorkspaceRepository
    private let workspaceSettings: WorkspaceSettings
    private let floatingAppsSettings: FloatingAppsSettings
    private let pictureInPictureManager: PictureInPictureManager
    private let workspaceTransitionManager: WorkspaceTransitionManager

    init(
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository,
        pictureInPictureManager: PictureInPictureManager,
        workspaceTransitionManager: WorkspaceTransitionManager
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceSettings = settingsRepository.workspaceSettings
        self.floatingAppsSettings = settingsRepository.floatingAppsSettings
        self.pictureInPictureManager = pictureInPictureManager
        self.workspaceTransitionManager = workspaceTransitionManager

        PermissionsManager.shared.askForAccessibilityPermissions()
        observe()
    }

    private func observe() {
        hideAgainSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] in self?.hideApps(in: $0) }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in
                self?.lastFocusedApp = [:]
                self?.activeWorkspace = [:]
                self?.mostRecentWorkspace = [:]
                self?.activeWorkspaceDetails = nil
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.activeWorkspace = [:]
                self?.mostRecentWorkspace = [:]
                self?.activeWorkspaceDetails = nil
            }
            .store(in: &cancellables)

        observeFocus()
    }

    private func observeFocus() {
        observeFocusCancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] application in
                guard let self else { return }

                if let activeWorkspace = activeWorkspace[application.display ?? ""] {
                    if activeWorkspace.apps.containsApp(application) {
                        lastFocusedApp[activeWorkspace.id] = application.toMacApp
                        lastFocusedFloatingApp[activeWorkspace.displayWithFallback] = nil
                        updateActiveWorkspace(activeWorkspace)
                    } else if floatingAppsSettings.floatingApps.containsApp(application) ||
                        workspaceSettings.keepUnassignedAppsOnSwitch,
                        application.bundleIdentifier != "com.apple.finder" || application.allWindows.count > 0 {
                        lastFocusedFloatingApp[activeWorkspace.displayWithFallback] = application.toMacApp
                    }
                }
            }
    }

    private func showApps(in workspace: Workspace, setFocus: Bool) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let floatingApps = floatingAppsSettings.floatingApps
        var appsToShow = regularApps
            .filter {
                workspace.apps.containsApp($0) ||
                    floatingApps.containsApp($0) &&
                    $0.isOnTheSameScreen(as: workspace)
            }

        observeFocusCancellable = nil
        defer { observeFocus() }

        if setFocus {
            let toFocus = findAppToFocus(in: workspace, apps: appsToShow)

            // Make sure to raise the app that should be focused
            // as the last one
            if let toFocus {
                appsToShow.removeAll { $0 == toFocus }
                appsToShow.append(toFocus)
            }

            for app in appsToShow {
                Logger.log("SHOW: \(app.localizedName ?? "")")

                if app == toFocus || app.isHidden || app.isMinimized {
                    app.raise()
                }

                pictureInPictureManager.showPipAppIfNeeded(app: app)
            }

            Logger.log("FOCUS: \(toFocus?.localizedName ?? "")")
            toFocus?.activate()
            centerCursorIfNeeded(in: toFocus?.frame)
        } else {
            for app in appsToShow {
                Logger.log("SHOW: \(app.localizedName ?? "")")
                app.raise()
            }
        }
    }

    private func hideApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let workspaceApps = workspace.apps + floatingAppsSettings.floatingApps
        let isAnyWorkspaceAppRunning = regularApps
            .contains { workspaceApps.containsApp($0) }
        let allAssignedApps = Set(workspaceRepository.workspaces.flatMap(\.apps).map(\.bundleIdentifier))

        let appsToHide = regularApps
            .filter {
                !$0.isHidden && !workspaceApps.containsApp($0) &&
                    (!workspaceSettings.keepUnassignedAppsOnSwitch || allAssignedApps.contains($0.bundleIdentifier ?? ""))
            }
            .filter { isAnyWorkspaceAppRunning || $0.bundleURL?.fileName != "Finder" }
            .filter { $0.isOnTheSameScreen(as: workspace) }

        for app in appsToHide {
            Logger.log("HIDE: \(app.localizedName ?? "")")

            if !pictureInPictureManager.hidePipAppIfNeeded(app: app) {
                app.hide()
            }
        }
    }

    private func findAppToFocus(
        in workspace: Workspace,
        apps: [NSRunningApplication]
    ) -> NSRunningApplication? {
        if workspace.appToFocus == nil, let floatingApp = lastFocusedFloatingApp[workspace.displayWithFallback] {
            return NSWorkspace.shared.runningApplications.find(floatingApp)
        }

        var appToFocus: NSRunningApplication?

        if workspace.appToFocus == nil {
            appToFocus = apps.find(lastFocusedApp[workspace.id])
        } else {
            appToFocus = apps.find(workspace.appToFocus)
        }

        let fallbackToLastApp = apps.findFirstMatch(with: workspace.apps.reversed())
        let fallbackToFinder = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == "com.apple.finder"
        }

        return appToFocus ?? fallbackToLastApp ?? fallbackToFinder
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard workspaceSettings.centerCursorOnWorkspaceChange, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func updateActiveWorkspace(_ workspace: Workspace) {
        lastWorkspaceActivation = Date()

        // Save the most recent workspace if it's not the current one
        let display = workspace.displayWithFallback
        if activeWorkspace[display]?.id != workspace.id {
            mostRecentWorkspace[display] = activeWorkspace[display]
        }

        activeWorkspace[display] = workspace

        activeWorkspaceDetails = .init(
            id: workspace.id,
            name: workspace.name,
            number: workspaceRepository.workspaces
                .firstIndex { $0.id == workspace.id }
                .map { "\($0 + 1)" },
            symbolIconName: workspace.symbolIconName,
            display: display
        )

        Integrations.runOnActivateIfNeeded(workspace: activeWorkspaceDetails!)
    }

    private func getCursorScreen() -> DisplayName? {
        let cursorLocation = NSEvent.mouseLocation

        return NSScreen.screens
            .first { NSMouseInRect(cursorLocation, $0.frame, false) }?
            .localizedName
    }
}

// MARK: - Workspace Actions
extension WorkspaceManager {
    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        Logger.log("")
        Logger.log("")
        Logger.log("WORKSPACE: \(workspace.name)")
        Logger.log("----")
        SpaceControl.hide()

        if !activeWorkspace.values.contains(where: { $0.id == workspace.id }) {
            workspaceTransitionManager.showTransitionIfNeeded(for: workspace)
        }

        updateActiveWorkspace(workspace)
        showApps(in: workspace, setFocus: setFocus)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)

        NotificationCenter.default.post(name: .workspaceChanged, object: workspace)
    }

    func assignApp(_ app: MacApp, to workspace: Workspace) {
        workspaceRepository.deleteAppFromAllWorkspaces(app: app)
        workspaceRepository.addApp(to: workspace.id, app: app)

        guard let targetWorkspace = workspaceRepository.workspaces
            .first(where: { $0.id == workspace.id }) else { return }

        let isTargetWorkspaceActive = activeWorkspace.values
            .contains(where: { $0.id == workspace.id })

        updateLastFocusedApp(app, in: targetWorkspace)

        if workspaceSettings.changeWorkspaceOnAppAssign {
            activateWorkspace(targetWorkspace, setFocus: true)
        } else if !isTargetWorkspaceActive {
            NSWorkspace.shared.runningApplications
                .find(app)?
                .hide()
            AppDependencies.shared.focusManager.nextWorkspaceApp()
        }

        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    func activateWorkspace(next: Bool, skipEmpty: Bool) {
        guard let screen = getCursorScreen() else { return }

        var screenWorkspaces = workspaceRepository.workspaces
            .filter { $0.displayWithFallback == screen }

        if !next {
            screenWorkspaces = screenWorkspaces.reversed()
        }

        guard let activeWorkspace = activeWorkspace[screen] ?? screenWorkspaces.first else { return }

        let nextWorkspaces = screenWorkspaces
            .drop(while: { $0.id != activeWorkspace.id })
            .dropFirst()

        var selectedWorkspace = nextWorkspaces.first ?? screenWorkspaces.first

        if skipEmpty {
            let runningApps = Set(
                NSWorkspace.shared.runningApplications
                    .filter { $0.activationPolicy == .regular }
                    .compactMap(\.bundleIdentifier)
            )

            selectedWorkspace = (nextWorkspaces + screenWorkspaces)
                .drop(while: { $0.apps.allSatisfy { !runningApps.contains($0.bundleIdentifier) } })
                .first
        }

        guard let selectedWorkspace, selectedWorkspace.id != activeWorkspace.id else { return }

        activateWorkspace(selectedWorkspace, setFocus: true)
    }

    func activateRecentWorkspace() {
        guard let screen = getCursorScreen(),
              let mostRecentWorkspace = mostRecentWorkspace[screen]
        else { return }

        activateWorkspace(mostRecentWorkspace, setFocus: true)
    }

    func activateWorkspaceIfActive(_ workspaceId: WorkspaceID) {
        guard activeWorkspace.values.contains(where: { $0.id == workspaceId }) else { return }
        guard let updatedWorkspace = workspaceRepository.workspaces.first(where: { $0.id == workspaceId }) else { return }

        activateWorkspace(updatedWorkspace, setFocus: false)
    }

    func updateLastFocusedApp(_ app: MacApp, in workspace: Workspace) {
        lastFocusedApp[workspace.id] = app
    }
}
