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

    private let dataUrl = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashspace/workspaces.json")

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = .prettyPrinted
        loadFromDisk()
        print(dataUrl)
    }

    func addWorkspace(name: String) {
        let workspace = Workspace(
            id: .init(),
            name: name,
            display: NSScreen.main?.localizedName ?? "",
            shortcut: nil,
            apps: []
        )
        workspaces.append(workspace)
        saveToDisk()
    }

    func updateWorkspace(_ workspace: Workspace) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        workspaces[workspaceIndex] = workspace
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
        guard let data = try? encoder.encode(workspaces) else { return }

        let directoryPath = dataUrl.deletingLastPathComponent()
        try? FileManager.default
            .createDirectory(at: directoryPath, withIntermediateDirectories: true)

        try? data.write(to: dataUrl)
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: dataUrl.path) else { return }
        guard let data = try? Data(contentsOf: dataUrl) else { return }

        workspaces = (try? decoder.decode([Workspace].self, from: data)) ?? []
    }
}
