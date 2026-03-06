//
//  WorkspaceSwitcherViewModel.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

struct WorkspaceSwitcherItem: Identifiable {
    let id: WorkspaceID
    let name: String
    let symbol: String
    let screenshotData: Data?
    let originalWorkspace: Workspace
}

final class WorkspaceSwitcherViewModel: ObservableObject {
    @Published private(set) var workspaces: [WorkspaceSwitcherItem] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var visibleSlots = 5
    @Published private(set) var showScreenshots = true

    var itemSize: CGSize {
        showScreenshots
            ? CGSize(width: 260, height: 190)
            : CGSize(width: 180, height: 120)
    }

    var itemSpacing: CGFloat {
        workspaces.count > visibleSlots ? 36 : 18
    }

    var containerSize: CGSize {
        let scrollViewPadding: CGFloat = 36
        let verticalPadding: CGFloat = 18
        let slotCount = min(visibleSlots, workspaces.count)
        let containerWidth = CGFloat(slotCount) * (itemSize.width + itemSpacing) - itemSpacing + 2 * scrollViewPadding
        let containerHeight = itemSize.height + 2 * verticalPadding

        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let adjustedContainerWidth = min(containerWidth, screenWidth - 100)

        return CGSize(
            width: adjustedContainerWidth,
            height: containerHeight
        )
    }

    private var cancellables = Set<AnyCancellable>()

    private let settings = AppDependencies.shared.workspaceSwitcherSettings
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let screenshotManager = AppDependencies.shared.workspaceScreenshotManager

    init() {
        refresh()

        NotificationCenter.default
            .publisher(for: .workspaceSwitcherNavigate)
            .compactMap { $0.object as? RawKeyCode }
            .sink { [weak self] in self?.handleArrowKey($0) }
            .store(in: &cancellables)
    }

    func refresh() {
        let activeWorkspaceIds = Set(workspaceManager.activeWorkspace.values.map(\.id))

        showScreenshots = settings.workspaceSwitcherShowScreenshots
        visibleSlots = settings.workspaceSwitcherVisibleWorkspaces

        var filteredWorkspaces = workspaceRepository.workspaces
            .filter { !settings.workspaceSwitcherCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }
            .filter(\.displays.isNotEmpty)

        if settings.workspaceSwitcherSortByLastActivation {
            filteredWorkspaces.sort {
                let time1 = workspaceManager.workspaceActivationTimes[$0.id] ?? Date.distantPast
                let time2 = workspaceManager.workspaceActivationTimes[$1.id] ?? Date.distantPast
                return time1 > time2
            }
        }

        workspaces = filteredWorkspaces.map { workspace in
            let key = WorkspaceScreenshotManager.ScreenshotKey(
                displayName: workspace.displays.first { $0 == DisplayName.current }
                    ?? workspace.displays.first ?? DisplayName.current,
                workspaceID: workspace.id
            )
            return WorkspaceSwitcherItem(
                id: workspace.id,
                name: workspace.name,
                symbol: workspace.symbolIconName ?? .defaultIconSymbol,
                screenshotData: screenshotManager.screenshots[key],
                originalWorkspace: workspace
            )
        }

        selectedIndex = workspaces.firstIndex {
            activeWorkspaceIds.contains($0.id) &&
                $0.originalWorkspace.isOnTheCurrentScreen
        } ?? 0
    }

    func onWorkspaceTap(_ index: Int) {
        selectedIndex = index

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WorkspaceSwitcher.hide(activateSelection: true)
        }
    }

    func advanceSelection(step: Int) {
        guard !workspaces.isEmpty else { return }
        selectedIndex = (selectedIndex + step + workspaces.count) % workspaces.count
    }

    func activateSelection() {
        guard workspaces.indices.contains(selectedIndex) else { return }
        workspaceManager.activateWorkspace(workspaces[selectedIndex].originalWorkspace, setFocus: true)
    }

    private func handleArrowKey(_ keyCode: RawKeyCode) {
        guard !workspaces.isEmpty else { return }

        let nextIndex: Int? = switch KeyCodesMap.toString[keyCode] {
        case "up", "right":
            (selectedIndex + 1) % workspaces.count
        case "down", "left":
            selectedIndex == 0 ? workspaces.count - 1 : selectedIndex - 1
        default:
            nil
        }

        if let nextIndex {
            selectedIndex = nextIndex
        }
    }
}
