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

    init(
        workspaceRepository: WorkspaceRepository,
        workspaceManager: WorkspaceManager
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceManager = workspaceManager
    }

    func startTracking() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .removeDuplicates()
            .throttle(for: .seconds(0.2), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] app in self?.activeApplicationChanged(app) }
            .store(in: &cancellables)
    }

    func stopTracking() {
        cancellables.removeAll()
    }

    private func activeApplicationChanged(_ app: NSRunningApplication) {
        // Skip if the app exists in any active workspace
        guard !workspaceManager.activeWorkspace.values
            .contains(where: { $0.apps.contains(app.localizedName ?? "") }) else { return }

        // Find the workspace that contains the app
        guard let workspace = workspaceRepository.workspaces
            .first(where: { $0.apps.contains(app.localizedName ?? "") }) else { return }

        // Activate the workspace if it's not already active
        if workspaceManager.activeWorkspace[workspace.display]?.id != workspace.id {
            print("\n\nFound workspace for app: \(workspace.name)")
            workspaceManager.activateWorkspace(workspace)
        }
    }
}
