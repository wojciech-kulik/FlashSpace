//
//  WorkspaceRepository.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import Foundation

final class WorkspaceRepository: ObservableObject {
    @Published private(set) var workspaces: [Workspace] = []

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

    func addWorkspace(_ workspace: Workspace) {
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

    func deleteWorkspaces(ids: Set<WorkspaceID>) {
        workspaces.removeAll { ids.contains($0.id) }
        notifyAboutChanges()
    }

    func addApp(to workspaceId: WorkspaceID, app: MacApp) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        guard !workspaces[workspaceIndex].apps.contains(app) else { return }

        workspaces[workspaceIndex].apps.append(app)
        notifyAboutChanges()
    }

    func deleteApp(from workspaceId: WorkspaceID, app: MacApp, notify: Bool = true) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }

        if workspaces[workspaceIndex].appToFocus == app {
            workspaces[workspaceIndex].appToFocus = nil
        }

        workspaces[workspaceIndex].apps.removeAll { $0 == app }
        if notify { notifyAboutChanges() }
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

    func reorderWorkspaces(newOrder: [WorkspaceID]) {
        let map = newOrder.enumerated().reduce(into: [WorkspaceID: Int]()) { $0[$1.element] = $1.offset }
        workspaces = workspaces.sorted { map[$0.id] ?? 0 < map[$1.id] ?? 0 }
        notifyAboutChanges()
    }

    func moveApps(_ apps: [MacApp], from sourceWorkspaceId: WorkspaceID, to targetWorkspaceId: WorkspaceID) {
        guard let sourceWorkspaceIndex = workspaces.firstIndex(where: { $0.id == sourceWorkspaceId }),
              let targetWorkspaceIndex = workspaces.firstIndex(where: { $0.id == targetWorkspaceId }) else { return }

        if let appToFocus = workspaces[sourceWorkspaceIndex].appToFocus, apps.contains(appToFocus) {
            workspaces[sourceWorkspaceIndex].appToFocus = nil
        }

        let targetAppBundleIds = workspaces[targetWorkspaceIndex].apps.map(\.bundleIdentifier).asSet
        let appsToAdd = apps.filter { !targetAppBundleIds.contains($0.bundleIdentifier) }

        workspaces[sourceWorkspaceIndex].apps.removeAll { apps.contains($0) }
        workspaces[targetWorkspaceIndex].apps.append(contentsOf: appsToAdd)

        notifyAboutChanges()
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    private func notifyAboutChanges() {
        profilesRepository.updateWorkspaces(workspaces)
    }
}
