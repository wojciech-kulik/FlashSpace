//
//  SpaceControlWindow.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

final class SpaceControlWindow: NSWindow, NSWindowDelegate {
    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCodesMap["escape"] {
            SpaceControl.hide(restoreFocus: true)
            return
        } else if ["up", "down", "right", "left"]
            .compactMap({ KeyCodesMap[$0] })
            .contains(event.keyCode) {
            NotificationCenter.default.post(name: .spaceControlArrowDown, object: event.keyCode)
            return
        }

        let settings = AppDependencies.shared.spaceControlSettings
        let workspaceManager = AppDependencies.shared.workspaceManager
        var workspaces = AppDependencies.shared.workspaceRepository.workspaces

        if settings.spaceControlCurrentDisplayWorkspaces {
            workspaces = workspaces.filter(\.isOnTheCurrentScreen)
        }

        var digit = Int(event.charactersIgnoringModifiers ?? "") ?? -1
        if (0...9).contains(digit) {
            SpaceControl.hide()
            digit = digit == 0 ? 10 : digit

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
