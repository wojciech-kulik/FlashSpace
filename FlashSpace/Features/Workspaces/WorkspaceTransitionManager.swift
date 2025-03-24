//
//  WorkspaceTransitionManager.swift
//
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//  Contribution by Sergio Patino - https://github.com/sergiopatino
//

import AppKit
import Combine
import SwiftUI

enum TransitionDirection {
    case left
    case right
    case none
}

final class WorkspaceTransitionManager {
    static let shared = WorkspaceTransitionManager()

    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var settings: WorkspaceSettings { AppDependencies.shared.workspaceSettings }
    private var lastWorkspaceId: WorkspaceID?

    private init() {
        observe()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .workspaceChanged)
            .compactMap { $0.object as? Workspace }
            .sink { [weak self] workspace in
                self?.showTransition(for: workspace)
                self?.lastWorkspaceId = workspace.id
            }
            .store(in: &cancellables)

        // Also listen for profile changes to reset the last workspace ID
        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in
                self?.lastWorkspaceId = nil
            }
            .store(in: &cancellables)
    }

    private func showTransition(for workspace: Workspace) {
        // Skip transitions if disabled or Space Control is visible
        guard settings.enableWorkspaceTransitions, !SpaceControl.isVisible else { return }

        // If there's an existing transition, close it first
        if window != nil {
            hideTransition()
        }

        // Determine transition direction based on workspace order
        let direction = determineDirection(for: workspace)

        // Create transition view
        let contentView = NSHostingView(
            rootView: WorkspaceTransitionView(direction: direction)
        )

        // Create window for the current screen
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        self.window = window

        // Set up window content
        window.contentView = contentView
        window.alphaValue = 0

        // Quick fade in for flash effect
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 1
        }

        // Show window
        window.orderFrontRegardless()

        // Brief flash effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.hideTransition()
        }
    }

    private func hideTransition() {
        guard let window else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.window = nil
        })
    }

    private func determineDirection(for workspace: Workspace) -> TransitionDirection {
        // If this is the first workspace activation, no direction
        guard let lastWorkspaceId else {
            return .none
        }

        // If it's the same workspace, no direction
        guard lastWorkspaceId != workspace.id else {
            return .none
        }

        // Get indexes of current and previous workspaces
        let workspaces = AppDependencies.shared.workspaceRepository.workspaces
        guard let currentIndex = workspaces.firstIndex(where: { $0.id == workspace.id }),
              let lastIndex = workspaces.firstIndex(where: { $0.id == lastWorkspaceId }) else {
            return .none
        }

        // Determine direction based on index comparison
        if currentIndex > lastIndex {
            return .right // Moving forward in the list
        } else {
            return .left // Moving backward in the list
        }
    }

    private func getCurrentWorkspaceIndex(for workspace: Workspace) -> Int? {
        AppDependencies.shared.workspaceRepository.workspaces
            .firstIndex { $0.id == workspace.id }
    }
}
