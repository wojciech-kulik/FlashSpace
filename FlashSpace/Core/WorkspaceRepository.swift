//
//  WorkspaceRepository.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class WorkspaceRepository {
    private(set) var workspaces: [Workspace] = []

    init() {
        loadFromDisk()
    }

    func addWorkspace(name: String) {
        let workspace = Workspace(
            id: .init(),
            name: name,
            display: "",
            shortcut: nil,
            apps: []
        )
        workspaces.append(workspace)
        saveToDisk()
    }

    func deleteWorkspace(id: WorkspaceID) {
        workspaces.removeAll { $0.id == id }
        saveToDisk()
    }

    func addApp(to workspaceId: WorkspaceID, app: String) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }

        workspaces[workspaceIndex].apps.append(app)
        saveToDisk()
    }

    func deleteApp(from workspaceId: WorkspaceID, app: String) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }

        workspaces[workspaceIndex].apps.removeAll { $0 == app }
        saveToDisk()
    }

    private func saveToDisk() {
        let encoder = JSONEncoder()

        guard let data = try? encoder.encode(workspaces) else { return }

        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("workspaces.json")

        guard let url else { return }

        try? data.write(to: url)
    }

    private func loadFromDisk() {
        let decoder = JSONDecoder()

        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("workspaces.json")

        guard let url else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard let data = try? Data(contentsOf: url) else { return }

        workspaces = (try? decoder.decode([Workspace].self, from: data)) ?? []
    }
}
