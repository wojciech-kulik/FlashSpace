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

        DispatchQueue.main.async {
            guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }

            self.activeApplicationChanged(activeApp, appLaunch: true)
        }
    }

    func startTracking() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .removeDuplicates()
            .sink { [weak self] app in self?.activeApplicationChanged(app, appLaunch: false) }
            .store(in: &cancellables)
    }

    func stopTracking() {
        cancellables.removeAll()
    }

    private func activeApplicationChanged(_ app: NSRunningApplication, appLaunch: Bool) {
        guard appLaunch || settingsRepository.workspaceSettings.activeWorkspaceOnFocusChange else { return }

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
        guard !settingsRepository.workspaceSettings.enablePictureInPictureSupport ||
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
            if settingsRepository.workspaceSettings.enablePictureInPictureSupport, app.supportsPictureInPicture {
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
}
