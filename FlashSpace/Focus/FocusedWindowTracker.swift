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
    }

    func startTracking() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .removeDuplicates()
            .sink { [weak self] app in self?.activeApplicationChanged(app) }
            .store(in: &cancellables)
    }

    func stopTracking() {
        cancellables.removeAll()
    }

    private func activeApplicationChanged(_ app: NSRunningApplication) {
        guard Date().timeIntervalSince(workspaceManager.lastWorkspaceActivation) > 0.2 else { return }

        // Skip if the app is floating
        guard settingsRepository.floatingApps?.containsApp(app) != true else { return }

        // Skip if the app exists in any active workspace
        guard !workspaceManager.activeWorkspace.values
            .contains(where: { $0.apps.containsApp(app) }) else { return }

        // Find the workspace that contains the app
        guard let workspace = workspaceRepository.workspaces
            .first(where: { $0.apps.containsApp(app) }) else { return }

        // Activate the workspace if it's not already active
        guard workspaceManager.activeWorkspace[workspace.displayWithFallback]?.id != workspace.id else { return }

        // Skip if the focused window is in Picture in Picture mode
        guard !settingsRepository.enablePictureInPictureSupport ||
            !app.supportsPictureInPicture ||
            app.focusedWindow?.isPictureInPicture(bundleId: app.bundleIdentifier) != true else { return }

        print("\n\nFound workspace for app: \(workspace.name)")
        workspaceManager.updateLastFocusedApp(app.toMacApp, in: workspace)
        workspaceManager.activateWorkspace(workspace, setFocus: false)
        app.activate()

        // Restore the app if it was hidden
        if settingsRepository.enablePictureInPictureSupport, app.supportsPictureInPicture {
            pictureInPictureManager.restoreAppIfNeeded(app: app)
        }
    }
}
