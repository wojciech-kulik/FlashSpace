//
//  FocusManager.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation
import ShortcutRecorder

final class FocusManager {
    var visibleApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isHidden }
    }

    var focusedApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
    var focusedAppFrame: CGRect? { focusedApp?.frame }

    private let workspaceRepository: WorkspaceRepository
    private let workspaceManager: WorkspaceManager
    private let settingsRepository: SettingsRepository

    init(
        workspaceRepository: WorkspaceRepository,
        workspaceManager: WorkspaceManager,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceManager = workspaceManager
        self.settingsRepository = settingsRepository
    }

    func getHotKeys() -> [(Shortcut, () -> ())] {
        let settings = settingsRepository

        guard settings.enableFocusManagement else { return [] }

        return [
            settings.focusLeft?.toShortcut().flatMap { ($0, focusLeft) },
            settings.focusRight?.toShortcut().flatMap { ($0, focusRight) },
            settings.focusUp?.toShortcut().flatMap { ($0, focusUp) },
            settings.focusDown?.toShortcut().flatMap { ($0, focusDown) },
            settings.focusNextWorkspaceApp?.toShortcut().flatMap { ($0, nextWorkspaceApp) },
            settings.focusPreviousWorkspaceApp?.toShortcut().flatMap { ($0, previousWorkspaceApp) }
        ].compactMap { $0 }
    }

    func nextWorkspaceApp() {
        guard let (index, apps) = getFocusedAppIndex() else { return }

        let appsQueue = apps.dropFirst(index + 1) + apps.prefix(index)
        let runningApps = Set(NSWorkspace.shared.runningApplications.map(\.localizedName))
        let nextApp = appsQueue.first(where: runningApps.contains)

        NSWorkspace.shared.runningApplications
            .first { $0.localizedName == nextApp }?
            .activate()
    }

    func previousWorkspaceApp() {
        guard let (index, apps) = getFocusedAppIndex() else { return }

        let runningApps = Set(NSWorkspace.shared.runningApplications.map(\.localizedName))
        let prefixApps = apps.prefix(index).reversed()
        let suffixApps = apps.suffix(apps.count - index - 1).reversed()
        let appsQueue = prefixApps + Array(suffixApps)
        let previousApp = appsQueue.first(where: runningApps.contains)

        NSWorkspace.shared.runningApplications
            .first { $0.localizedName == previousApp }?
            .activate()
    }

    func focusRight() {
        focus { focusedAppFrame, other in
            other.maxX > focusedAppFrame.maxX &&
                other.verticalIntersect(with: focusedAppFrame)
        }
    }

    func focusLeft() {
        focus { focusedAppFrame, other in
            other.minX < focusedAppFrame.minX &&
                other.verticalIntersect(with: focusedAppFrame)
        }
    }

    func focusDown() {
        focus { focusedAppFrame, other in
            other.maxY > focusedAppFrame.maxY &&
                other.horizontalIntersect(with: focusedAppFrame)
        }
    }

    func focusUp() {
        focus { focusedAppFrame, other in
            other.minY < focusedAppFrame.minY &&
                other.horizontalIntersect(with: focusedAppFrame)
        }
    }

    private func focus(predicate: (CGRect, CGRect) -> Bool) {
        guard let focusedAppFrame else { return }

        let toFocus = visibleApps
            .flatMap { app in
                app.allWindows.map {
                    (app: app, window: $0.window, frame: $0.frame)
                }
            }
            .filter { predicate(focusedAppFrame, $0.frame) }
            .min { $0.frame.distance(to: focusedAppFrame) < $1.frame.distance(to: focusedAppFrame) }

        toFocus?.window.focus()
        toFocus?.app.activate()
        centerCursorIfNeeded(in: toFocus?.frame)
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard settingsRepository.centerCursorOnFocusChange, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func getFocusedAppIndex() -> (Int, [String])? {
        guard let focusedApp = focusedApp?.localizedName else { return nil }

        let workspace = workspaceManager.activeWorkspace[NSScreen.main?.localizedName ?? ""]
            ?? workspaceRepository.workspaces.first { $0.apps.contains(focusedApp) }

        guard let apps = workspace?.apps else { return nil }

        let index = apps.firstIndex(of: focusedApp) ?? 0

        return (index, apps)
    }
}
