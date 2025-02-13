//
//  SpaceControlWindow.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder
import SwiftUI

final class SpaceControlWindow: NSWindow, NSWindowDelegate {
    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCode.escape.rawValue {
            SpaceControl.hide()
            return
        } else if [KeyCode.downArrow, .upArrow, .leftArrow, .rightArrow].map(\.rawValue).contains(event.keyCode) {
            NotificationCenter.default.post(name: .spaceControlArrowDown, object: event.keyCode)
            return
        }

        let settings = AppDependencies.shared.settingsRepository
        let workspaceManager = AppDependencies.shared.workspaceManager
        var workspaces = AppDependencies.shared.workspaceRepository.workspaces

        if settings.spaceControlCurrentDisplayWorkspaces {
            workspaces = workspaces.filter(\.isOnTheCurrentScreen)
        }

        let digit = Int(event.charactersIgnoringModifiers ?? "") ?? -1
        if digit >= 1, digit <= 10 {
            SpaceControl.hide()

            if let workspace = workspaces[safe: digit - 1] {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
            }
            return
        }

        super.keyDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        SpaceControl.hide()
        return super.resignFirstResponder()
    }

    func windowDidResignKey(_ notification: Notification) {
        SpaceControl.hide()
    }
}
