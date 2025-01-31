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

    init(
        workspaceRepository: WorkspaceRepository,
        workspaceManager: WorkspaceManager,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceManager = workspaceManager
        self.settingsRepository = settingsRepository
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
        guard settingsRepository.floatingApps?.contains(app.localizedName ?? "") != true else { return }

        // Skip if the app exists in any active workspace
        guard !workspaceManager.activeWorkspace.values
            .contains(where: { $0.apps.contains(app.localizedName ?? "") }) else { return }

        // Find the workspace that contains the app
        guard let workspace = workspaceRepository.workspaces
            .first(where: { $0.apps.contains(app.localizedName ?? "") }) else { return }

        // Activate the workspace if it's not already active
        if workspaceManager.activeWorkspace[workspace.displayWithFallback]?.id != workspace.id {
            print("\n\nFound workspace for app: \(workspace.name)")
            workspaceManager.activateWorkspace(workspace, setFocus: false)
            app.activate()
        }
    }
}
