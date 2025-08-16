//
//  SpaceControlViewModel.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
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
    @Published var isVisible = false

    @Published private(set) var workspaces: [SpaceControlWorkspace] = []
    @Published private(set) var numberOfRows = 0
    @Published private(set) var numberOfColumns = 0
    @Published private(set) var tileSize: CGSize = .zero

    var wallpaperImage: NSImage? {
        if let screen = NSScreen.main,
           let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen) {
            return NSImage(contentsOf: wallpaperURL)
        }

        return nil
    }

    private var cancellables = Set<AnyCancellable>()

    private let settings = AppDependencies.shared.spaceControlSettings
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let screenshotManager = AppDependencies.shared.workspaceScreenshotManager
    private let displayManager = AppDependencies.shared.displayManager

    init() {
        refresh()

        self.isVisible = !settings.enableSpaceControlTilesAnimations

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
        let activeWorkspaceIds = workspaceManager.activeWorkspace.map(\.value.id).asSet
        let mainDisplay = NSScreen.main?.localizedName ?? ""

        workspaces = Array(
            workspaceRepository.workspaces
                .filter { !settings.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }
                .prefix(15)
                .enumerated()
                .map {
                    let workspace = $0.element
                    let displayName = settings.spaceControlCurrentDisplayWorkspaces
                        ? mainDisplay
                        : self.mainDisplay(for: workspace)
                    let key = WorkspaceScreenshotManager.ScreenshotKey(
                        displayName: displayName,
                        workspaceID: workspace.id
                    )
                    return SpaceControlWorkspace(
                        index: $0.offset,
                        name: workspace.name,
                        symbol: workspace.symbolIconName ?? .defaultIconSymbol,
                        screenshotData: screenshotManager.screenshots[key],
                        isActive: activeWorkspaceIds.contains(workspace.id),
                        originalWorkspace: workspace
                    )
                }
        )
        calculateColsAndRows(workspaces.count)
        calculateTileSize()
    }

    private func mainDisplay(for workspace: Workspace) -> DisplayName {
        let workspaceDisplays = workspace.displays

        return workspaceDisplays.count == 1
            ? workspaceDisplays.first!
            : displayManager.lastActiveDisplay(from: workspaceDisplays)
    }

    private func calculateColsAndRows(_ workspaceCount: Int) {
        let maxNumberOfRows = 3.0

        numberOfColumns = workspaceCount <= 3
            ? workspaceCount
            : max(3, Int(ceil(Double(workspaceCount) / maxNumberOfRows)))
        numberOfColumns = min(numberOfColumns, settings.spaceControlMaxColumns)

        numberOfRows = Int(ceil(Double(workspaceCount) / Double(numberOfColumns)))
    }

    private func calculateTileSize() {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 3024, height: 1964)

        let width = screenFrame.width / CGFloat(numberOfColumns) - 120.0
        let height = screenFrame.height / CGFloat(numberOfRows) - 120.0

        let firstScreenshot = workspaces
            .lazy
            .compactMap { $0.screenshotData.flatMap(NSImage.init(data:)) }
            .first

        guard let firstScreenshot else {
            tileSize = CGSize(width: width, height: min(height, width * 10.0 / 16.0))
            return
        }

        let tileRatio = width / height
        let screenshotRatio = firstScreenshot.size.width / firstScreenshot.size.height

        if tileRatio > screenshotRatio {
            // Tile is wider than screenshot, adjust width
            let scaledWidth = height * screenshotRatio
            tileSize = CGSize(width: scaledWidth, height: height)
        } else {
            // Tile is taller than screenshot, adjust height
            let scaledHeight = width / screenshotRatio
            tileSize = CGSize(width: width, height: scaledHeight)
        }
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
