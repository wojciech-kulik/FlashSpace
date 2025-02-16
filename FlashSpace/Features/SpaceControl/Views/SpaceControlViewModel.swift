//
//  SpaceControlViewModel.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import SwiftUI

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

    private var cancellables = Set<AnyCancellable>()

    private let settings = AppDependencies.shared.spaceControlSettings
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let screenshotManager = AppDependencies.shared.workspaceScreenshotManager

    init() {
        refresh()

        NotificationCenter.default
            .publisher(for: .spaceControlArrowDown)
            .compactMap { $0.object as? RawKeyCode }
            .sink { [weak self] in self?.handleArrowKey($0) }
            .store(in: &cancellables)
    }

    func onWorkspaceTap(_ workspace: SpaceControlWorkspace) {
        workspaceManager.activateWorkspace(workspace.originalWorkspace, setFocus: true)
    }

    func refresh() {
        let activeWorkspaceIds = Set(workspaceManager.activeWorkspace.map(\.value.id))

        workspaces = Array(
            workspaceRepository.workspaces
                .filter { !settings.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }
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
        calculateColsAndRows(workspaces.count)
    }

    private func calculateColsAndRows(_ workspaceCount: Int) {
        let maxNumberOfRows = 3.0

        numberOfColumns = workspaceCount <= 3
            ? workspaceCount
            : max(3, Int(ceil(Double(workspaceCount) / maxNumberOfRows)))

        numberOfRows = Int(ceil(Double(workspaceCount) / Double(numberOfColumns)))
    }

    private func handleArrowKey(_ keyCode: RawKeyCode) {
        let activeWorkspaceIndex = workspaces.firstIndex {
            $0.isActive && $0.originalWorkspace.isOnTheCurrentScreen
        }
        guard let activeWorkspaceIndex else { return }

        let workspace: Workspace? = switch KeyCodesMap.toString[keyCode] {
        case "down":
            workspaces[safe: activeWorkspaceIndex + numberOfColumns]?.originalWorkspace
        case "up":
            workspaces[safe: activeWorkspaceIndex - numberOfColumns]?.originalWorkspace
        case "right":
            workspaces[safe: (activeWorkspaceIndex + 1) % workspaces.count]?.originalWorkspace
        case "left":
            workspaces[
                safe: activeWorkspaceIndex == 0
                    ? workspaces.count - 1
                    : activeWorkspaceIndex - 1
            ]?.originalWorkspace
        default:
            nil
        }

        if let workspace {
            SpaceControl.hide()
            workspaceManager.activateWorkspace(workspace, setFocus: true)
        }
    }
}
