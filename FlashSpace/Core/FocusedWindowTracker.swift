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
        let workspaces = AppDependencies.shared.workspaceRepository.workspaces
        let workspace = workspaces.first { $0.apps.contains(app.localizedName ?? "") }

        guard let workspace else { return }

        let workspaceManager = AppDependencies.shared.workspaceManager

        if workspaceManager.activeWorkspace?.id != workspace.id {
            print("Found workspace for app: \(workspace.name)")
            workspaceManager.activateWorkspace(workspace)
        }
    }
}
