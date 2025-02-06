//
//  WorkspaceRepository.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class WorkspaceRepository {
    private(set) var workspaces: [Workspace] = []

    private let profilesRepository: ProfilesRepository

    init(profilesRepository: ProfilesRepository) {
        self.profilesRepository = profilesRepository
        self.workspaces = profilesRepository.selectedProfile.workspaces

        profilesRepository.onProfileChange = { [weak self] profile in
            self?.workspaces = profile.workspaces
        }
    }

    func addWorkspace(name: String) {
        let workspace = Workspace(
            id: .init(),
            name: name,
            display: NSScreen.main?.localizedName ?? "",
            activateShortcut: nil,
            assignAppShortcut: nil,
            apps: []
        )
        workspaces.append(workspace)
        notifyAboutChanges()
    }

    func updateWorkspace(_ workspace: Workspace) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        workspaces[workspaceIndex] = workspace
        notifyAboutChanges()
        AppDependencies.shared.hotKeysManager.refresh()
    }

    func deleteWorkspace(id: WorkspaceID) {
        workspaces.removeAll { $0.id == id }
        notifyAboutChanges()
    }

    func addApp(to workspaceId: WorkspaceID, app: MacApp) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        guard !workspaces[workspaceIndex].apps.contains(app) else { return }

        workspaces[workspaceIndex].apps.append(app)
        notifyAboutChanges()
    }

    func deleteApp(from workspaceId: WorkspaceID, app: MacApp) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }

        if workspaces[workspaceIndex].appToFocus == app {
            workspaces[workspaceIndex].appToFocus = nil
        }

        workspaces[workspaceIndex].apps.removeAll { $0 == app }
        notifyAboutChanges()
    }

    func deleteAppFromAllWorkspaces(app: MacApp) {
        for (index, var workspace) in workspaces.enumerated() {
            workspace.apps.removeAll { $0 == app }
            if workspace.appToFocus == app {
                workspace.appToFocus = nil
            }

            workspaces[index] = workspace
        }
        notifyAboutChanges()
    }

    func moveUp(workspaceId: WorkspaceID) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        guard index > 0 else { return }

        let tmp = workspaces[index - 1]
        workspaces[index - 1] = workspaces[index]
        workspaces[index] = tmp
        notifyAboutChanges()
    }

    func moveDown(workspaceId: WorkspaceID) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        guard index < workspaces.count - 1 else { return }

        let tmp = workspaces[index + 1]
        workspaces[index + 1] = workspaces[index]
        workspaces[index] = tmp
        notifyAboutChanges()
    }

    private func notifyAboutChanges() {
        profilesRepository.updateWorkspaces(workspaces)
    }
}
