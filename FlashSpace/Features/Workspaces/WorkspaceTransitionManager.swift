//
//  WorkspaceTransitionManager.swift
//
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//  Contribution by Sergio Patino - https://github.com/sergiopatino
//

import AppKit

final class WorkspaceTransitionManager {
    private var window: NSWindow?
    private let settings: WorkspaceSettings

    init(workspaceSettings: WorkspaceSettings) {
        self.settings = workspaceSettings
    }

    func showTransitionIfNeeded(for workspace: Workspace) {
        guard settings.enableWorkspaceTransitions else {
            // Small delay to allow workspace to be activated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .workspaceTransitionFinished, object: workspace)
            }
            return
        }
        guard window == nil, !SpaceControl.isVisible else { return }
        guard let screen = NSScreen.screen(workspace.displayWithFallback) else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.alphaValue = CGFloat(settings.workspaceTransitionDimming)
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.black.cgColor

        window.orderFrontRegardless()
        self.window = window

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideTransition(for: workspace)
        }
    }

    private func hideTransition(for workspace: Workspace) {
        guard let window else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = settings.workspaceTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.window = nil
            NotificationCenter.default.post(name: .workspaceTransitionFinished, object: workspace)
        })
    }
}
