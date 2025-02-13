//
//  SpaceControlViewModel.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct SpaceControlWorkspace {
    let index: Int
    let name: String
    let symbol: String
    let screenshotData: Data?
    let isActive: Bool
    let originalWorkspace: Workspace
}

final class SpaceControlViewModel: ObservableObject {
    @Published private(set) var workspaces: [SpaceControlWorkspace] = []
    @Published private(set) var numberOfRows = 0
    @Published private(set) var numberOfColumns = 0

    private let settingsRepository = AppDependencies.shared.settingsRepository
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let screenshotManager = AppDependencies.shared.workspaceScreenshotManager

    init() {
        refresh()
    }

    func onWorkspaceTap(_ workspace: SpaceControlWorkspace) {
        workspaceManager.activateWorkspace(workspace.originalWorkspace, setFocus: true)
    }

    func refresh() {
        let activeWorkspaceIds = Set(workspaceManager.activeWorkspace.map(\.value.id))

        workspaces = Array(
            workspaceRepository.workspaces
                .filter { !settingsRepository.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }
                .prefix(15)
                .enumerated()
                .map {
                    SpaceControlWorkspace(
                        index: $0.offset,
                        name: $0.element.name,
                        symbol: $0.element.symbolIconName ?? .defaultIconSymbol,
                        screenshotData: screenshotManager.screenshots[$0.element.id],
                        isActive: activeWorkspaceIds.contains($0.element.id),
                        originalWorkspace: $0.element
                    )
                }
        )

        calculateColsAndRows()
    }

    private func calculateColsAndRows() {
        let maxNumberOfRows = 3.0

        numberOfColumns = workspaces.count <= 3
            ? workspaces.count
            : max(3, Int(ceil(Double(workspaces.count) / maxNumberOfRows)))

        numberOfRows = Int(ceil(Double(workspaces.count) / Double(numberOfColumns)))
    }
}
