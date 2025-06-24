//
//  WorkspaceTransitionManager.swift
//
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//  Contribution by Sergio Patino - https://github.com/sergiopatino
//

import AppKit

final class WorkspaceTransitionManager {
    private var windows: [NSWindow] = []
    private let settings: WorkspaceSettings

    init(workspaceSettings: WorkspaceSettings) {
        self.settings = workspaceSettings
    }

    func showTransitionIfNeeded(for workspace: Workspace, on displays: Set<DisplayName>) {
        guard settings.enableWorkspaceTransitions else {
            // Small delay to allow workspace to be activated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .workspaceTransitionFinished, object: workspace)
            }
            return
        }
        guard windows.isEmpty, !SpaceControl.isVisible else { return }

        let screens = NSScreen.screens.filter { displays.contains($0.localizedName) }

        guard !screens.isEmpty else { return }

        for screen in screens {
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
            windows.append(window)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideTransition(for: workspace)
        }
    }

    private func hideTransition(for workspace: Workspace) {
        guard !windows.isEmpty else { return }

        NSAnimationContext.runAnimationGroup({ [weak self] context in
            context.duration = self?.settings.workspaceTransitionDuration ?? 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self?.windows.forEach { window in
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: { [weak self] in
            self?.windows.forEach { window in
                window.orderOut(nil)
            }
            self?.windows.removeAll()
            NotificationCenter.default.post(name: .workspaceTransitionFinished, object: workspace)
        })
    }
}
