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

    private(set) var lastFocusedApp: [ProfileId: [WorkspaceID: MacApp]] = [:]
    private(set) var activeWorkspace: [DisplayName: Workspace] = [:]
    private(set) var mostRecentWorkspace: [DisplayName: Workspace] = [:]
    private(set) var lastWorkspaceActivation = Date.distantPast

    private var cancellables = Set<AnyCancellable>()
    private var observeFocusCancellable: AnyCancellable?
    private var appsHiddenManually: [WorkspaceID: [MacApp]] = [:]
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    private let workspaceRepository: WorkspaceRepository
    private let workspaceSettings: WorkspaceSettings
    private let profilesRepository: ProfilesRepository
    private let floatingAppsSettings: FloatingAppsSettings
    private let pictureInPictureManager: PictureInPictureManager
    private let workspaceTransitionManager: WorkspaceTransitionManager
    private let displayManager: DisplayManager

    init(
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository,
        profilesRepository: ProfilesRepository,
        pictureInPictureManager: PictureInPictureManager,
        workspaceTransitionManager: WorkspaceTransitionManager,
        displayManager: DisplayManager
    ) {
        self.workspaceRepository = workspaceRepository
        self.profilesRepository = profilesRepository
        self.workspaceSettings = settingsRepository.workspaceSettings
        self.floatingAppsSettings = settingsRepository.floatingAppsSettings
        self.pictureInPictureManager = pictureInPictureManager
        self.workspaceTransitionManager = workspaceTransitionManager
        self.displayManager = displayManager

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
                self?.rememberLastFocusedApp(application, retry: true)
            }
    }

    private func rememberLastFocusedApp(_ application: NSRunningApplication, retry: Bool) {
        guard application.display != nil else {
            if retry {
                Logger.log("Retrying to get display for \(application.localizedName ?? "")")
                return DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                        self.rememberLastFocusedApp(frontmostApp, retry: false)
                    }
                }
            } else {
                return Logger.log("Unable to get display for \(application.localizedName ?? "")")
            }
        }

        let focusedDisplay = NSScreen.main?.localizedName ?? ""

        if let activeWorkspace = activeWorkspace[focusedDisplay], activeWorkspace.apps.containsApp(application) {
            updateLastFocusedApp(application.toMacApp, in: activeWorkspace)
            updateActiveWorkspace(activeWorkspace, on: [focusedDisplay])
        }

        displayManager.trackDisplayFocus(on: focusedDisplay, for: application)
    }

    private func showApps(in workspace: Workspace, setFocus: Bool, on displays: Set<DisplayName>) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let floatingApps = floatingAppsSettings.floatingApps
        let hiddenApps = appsHiddenManually[workspace.id] ?? []
        var appsToShow = regularApps
            .filter { !hiddenApps.containsApp($0) }
            .filter {
                workspace.apps.containsApp($0) ||
                    floatingApps.containsApp($0) && $0.isOnAnyDisplay(displays)
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
        let allAssignedApps = workspaceRepository.workspaces
            .flatMap(\.apps)
            .map(\.bundleIdentifier)
            .asSet
        let displays = workspace.displays

        let appsToHide = regularApps
            .filter {
                !$0.isHidden && !workspaceApps.containsApp($0) &&
                    (!workspaceSettings.keepUnassignedAppsOnSwitch || allAssignedApps.contains($0.bundleIdentifier ?? ""))
            }
            .filter { isAnyWorkspaceAppRunning || $0.bundleURL?.fileName != "Finder" }
            .filter { $0.isOnAnyDisplay(displays) }

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
        if workspace.appToFocus == nil {
            let displays = workspace.displays
            if let floatingEntry = displayManager.lastFocusedDisplay(where: {
                let isFloating = floatingAppsSettings.floatingApps.contains($0.app)
                let isUnassigned = workspaceSettings.keepUnassignedAppsOnSwitch &&
                    !workspaceRepository.workspaces.flatMap(\.apps).contains($0.app)
                return (isFloating || isUnassigned) && displays.contains($0.display)
            }),
                let runningApp = NSWorkspace.shared.runningApplications.find(floatingEntry.app) {
                return runningApp
            }
        }

        var appToFocus: NSRunningApplication?

        if workspace.appToFocus == nil {
            appToFocus = apps.find(lastFocusedApp[profilesRepository.selectedProfile.id, default: [:]][workspace.id])
        } else {
            appToFocus = apps.find(workspace.appToFocus)
        }

        let fallbackToLastApp = apps.findFirstMatch(with: workspace.apps.reversed())
        let fallbackToFinder = NSWorkspace.shared.runningApplications.first(where: \.isFinder)

        return appToFocus ?? fallbackToLastApp ?? fallbackToFinder
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard workspaceSettings.centerCursorOnWorkspaceChange, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func updateActiveWorkspace(_ workspace: Workspace, on displays: Set<DisplayName>) {
        lastWorkspaceActivation = Date()

        // Save the most recent workspace if it's not the current one
        for display in displays {
            if activeWorkspace[display]?.id != workspace.id {
                mostRecentWorkspace[display] = activeWorkspace[display]
            }
            activeWorkspace[display] = workspace
        }

        activeWorkspaceDetails = .init(
            id: workspace.id,
            name: workspace.name,
            number: workspaceRepository.workspaces
                .firstIndex { $0.id == workspace.id }
                .map { "\($0 + 1)" },
            symbolIconName: workspace.symbolIconName,
            display: workspace.displayForPrint
        )

        Integrations.runOnActivateIfNeeded(workspace: activeWorkspaceDetails!)
    }

    private func rememberHiddenApps(workspaceToActivate: Workspace) {
        guard !workspaceSettings.restoreHiddenAppsOnSwitch else {
            appsHiddenManually = [:]
            return
        }

        let hiddenApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.isHidden || $0.isMinimized }

        for activeWorkspace in activeWorkspace.values {
            guard activeWorkspace.id != workspaceToActivate.id else { continue }

            appsHiddenManually[activeWorkspace.id] = []
        }

        for (display, activeWorkspace) in activeWorkspace {
            guard activeWorkspace.id != workspaceToActivate.id else { continue }

            let activeWorkspaceOtherDisplays = activeWorkspace.displays.subtracting([display])
            appsHiddenManually[activeWorkspace.id, default: []] += hiddenApps
                .filter {
                    activeWorkspace.apps.containsApp($0) &&
                        $0.isOnAnyDisplay([display]) && !$0.isOnAnyDisplay(activeWorkspaceOtherDisplays)
                }
                .map(\.toMacApp)
        }
    }
}

// MARK: - Workspace Actions
extension WorkspaceManager {
    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        let displays = workspace.displays

        Logger.log("")
        Logger.log("")
        Logger.log("WORKSPACE: \(workspace.name)")
        Logger.log("DISPLAYS: \(displays.joined(separator: ", "))")
        Logger.log("----")
        SpaceControl.hide()

        guard displays.isNotEmpty else {
            Logger.log("No displays found for workspace: \(workspace.name) - skipping")
            return
        }

        workspaceTransitionManager.showTransitionIfNeeded(for: workspace, on: displays)

        rememberHiddenApps(workspaceToActivate: workspace)
        updateActiveWorkspace(workspace, on: displays)
        showApps(in: workspace, setFocus: setFocus, on: displays)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)

        NotificationCenter.default.post(name: .workspaceChanged, object: workspace)
    }

    func assignApps(_ apps: [MacApp], to workspace: Workspace) {
        for app in apps {
            workspaceRepository.deleteAppFromAllWorkspaces(app: app)
            workspaceRepository.addApp(to: workspace.id, app: app)
        }

        NotificationCenter.default.post(name: .appsListChanged, object: nil)
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

    func hideUnassignedApps() {
        let activeWorkspace = workspaceRepository.workspaces
            .first(where: { $0.id == activeWorkspaceDetails?.id })

        guard let activeWorkspace else { return }

        let appsToHide = NSWorkspace.shared.runningApplications
            .regularVisibleApps(onDisplays: activeWorkspace.displays, excluding: activeWorkspace.apps)

        for app in appsToHide {
            Logger.log("CLEAN UP: \(app.localizedName ?? "")")

            if !pictureInPictureManager.hidePipAppIfNeeded(app: app) {
                app.hide()
            }
        }
    }

    func activateWorkspace(next: Bool, skipEmpty: Bool, loop: Bool) {
        guard let screen = displayManager.getCursorScreen() else { return }

        var screenWorkspaces = workspaceRepository.workspaces
            .filter { $0.displays.contains(screen) }

        if !next {
            screenWorkspaces = screenWorkspaces.reversed()
        }

        guard let activeWorkspace = activeWorkspace[screen] ?? screenWorkspaces.first else { return }

        let nextWorkspaces = screenWorkspaces
            .drop(while: { $0.id != activeWorkspace.id })
            .dropFirst()

        var selectedWorkspace = nextWorkspaces.first ?? (loop ? screenWorkspaces.first : nil)

        if skipEmpty {
            let runningApps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap(\.bundleIdentifier)
                .asSet

            selectedWorkspace = (nextWorkspaces + (loop ? screenWorkspaces : []))
                .drop(while: { $0.apps.allSatisfy { !runningApps.contains($0.bundleIdentifier) } })
                .first
        }

        guard let selectedWorkspace, selectedWorkspace.id != activeWorkspace.id else { return }

        activateWorkspace(selectedWorkspace, setFocus: true)
    }

    func activateRecentWorkspace() {
        guard let screen = displayManager.getCursorScreen(),
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
        lastFocusedApp[profilesRepository.selectedProfile.id, default: [:]][workspace.id] = app
    }
}
