//
//  FocusedWindowTracker.swift
//
//  Created by Wojciech Kulik on 20/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class FocusedWindowTracker {
    private var cancellables = Set<AnyCancellable>()

    private let workspaceRepository: WorkspaceRepository
    private let workspaceManager: WorkspaceManager
    private let settingsRepository: SettingsRepository
    private let pictureInPictureManager: PictureInPictureManager

    init(
        workspaceRepository: WorkspaceRepository,
        workspaceManager: WorkspaceManager,
        settingsRepository: SettingsRepository,
        pictureInPictureManager: PictureInPictureManager
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceManager = workspaceManager
        self.settingsRepository = settingsRepository
        self.pictureInPictureManager = pictureInPictureManager

        activateWorkspaceForFocusedApp(force: true)
    }

    func startTracking() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { $0.activationPolicy == .regular }
            .removeDuplicates()
            .sink { [weak self] app in
                self?.activeApplicationChanged(app, force: false)
                self?.autoAssignAppToWorkspaceIfNeeded(app)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in self?.activateWorkspaceForFocusedApp() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.activateWorkspaceForFocusedApp(force: true) }
            .store(in: &cancellables)
    }

    func stopTracking() {
        cancellables.removeAll()
    }

    private func activateWorkspaceForFocusedApp(force: Bool = false) {
        DispatchQueue.main.async {
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }

            self.activeApplicationChanged(activeApp, force: force)
        }
    }

    private func activeApplicationChanged(_ app: NSRunningApplication, force: Bool) {
        let workspaceSettings = settingsRepository.workspaceSettings
        let shouldActivate = workspaceSettings.activeWorkspaceOnFocusChange &&
            (!workspaceSettings.autoAssignAppsToWorkspaces || !workspaceSettings.autoAssignAlreadyAssignedApps)

        guard force || shouldActivate else { return }

        let activeWorkspaces = workspaceManager.activeWorkspace.values

        // Skip if the workspace was activated recently
        guard Date().timeIntervalSince(workspaceManager.lastWorkspaceActivation) > 0.2 else { return }

        // Skip if the app is floating
        guard !settingsRepository.floatingAppsSettings.floatingApps.containsApp(app) else { return }

        // Find the workspace that contains the app.
        // The same app can be in multiple workspaces, the highest priority has the one
        // from the active workspace.
        guard let workspace = (activeWorkspaces + workspaceRepository.workspaces)
            .first(where: { $0.apps.containsApp(app) }) else { return }

        // Skip if the workspace is already active
        guard activeWorkspaces.count(where: { $0.id == workspace.id }) < workspace.displays.count else { return }

        // Skip if the focused window is in Picture in Picture mode
        guard !workspaceSettings.enablePictureInPictureSupport ||
            !app.supportsPictureInPicture ||
            app.focusedWindow?.isPictureInPicture(bundleId: app.bundleIdentifier) != true else { return }

        let activate = { [self] in
            Logger.log("")
            Logger.log("")
            Logger.log("Activating workspace for app: \(workspace.name)")
            workspaceManager.updateLastFocusedApp(app.toMacApp, in: workspace)
            workspaceManager.activateWorkspace(workspace, setFocus: false)
            app.activate()

            // Restore the app if it was hidden
            if workspaceSettings.enablePictureInPictureSupport, app.supportsPictureInPicture {
                pictureInPictureManager.restoreAppIfNeeded(app: app)
            }
        }

        if workspace.isDynamic, workspace.displays.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                activate()
            }
        } else {
            activate()
        }
    }

    private func autoAssignAppToWorkspaceIfNeeded(_ app: NSRunningApplication) {
        guard settingsRepository.workspaceSettings.autoAssignAppsToWorkspaces else { return }

        // Skip if the app is floating
        guard !settingsRepository.floatingAppsSettings.floatingApps.containsApp(app) else { return }

        // Skip if the app is already assigned to a workspace
        guard settingsRepository.workspaceSettings.autoAssignAlreadyAssignedApps ||
            !workspaceRepository.workspaces.contains(where: { $0.apps.containsApp(app) }) else { return }

        // Assign the app to the active workspace on the same display, or to the first active workspace if there is no active
        // workspace on the same display
        let display = DisplayName.current
        let activeWorkspaces = workspaceManager.activeWorkspace.values
        let activeWorkspace = activeWorkspaces.first { $0.displays.contains(display) }
            ?? activeWorkspaces.first

        if let activeWorkspace {
            workspaceManager.assignApp(app.toMacApp, to: activeWorkspace)
        }
    }
}
