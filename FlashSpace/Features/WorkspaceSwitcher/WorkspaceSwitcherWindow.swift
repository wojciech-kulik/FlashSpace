//
//  WorkspaceSwitcherWindow.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit

final class WorkspaceSwitcherWindow: NSWindow, NSWindowDelegate {
    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCodesMap["escape"] {
            WorkspaceSwitcher.cancel()
            return
        } else if ["up", "down", "right", "left"]
            .compactMap({ KeyCodesMap[$0] })
            .contains(event.keyCode) {
            NotificationCenter.default.post(
                name: .workspaceSwitcherNavigate,
                object: event.keyCode
            )
            return
        }

        super.keyDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        WorkspaceSwitcher.cancel()
        return super.resignFirstResponder()
    }

    func windowDidResignKey(_ notification: Notification) {
        WorkspaceSwitcher.cancel()
    }
}
