//
//  NSRunningApplication+Actions.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    func raise() {
        guard let mainWindow else {
            unhide()
            return
        }

        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
    }

    /// Position is in window coordinates where (0,0) is top-left corner
    /// and it is relative to the main screen.
    func setPosition(_ position: CGPoint) {
        mainWindow?.setPosition(position)
    }

    func centerApp(display: DisplayName) {
        guard let appFrame = frame else {
            return Logger.log("Could not get frame for app: \(localizedName ?? "")")
        }

        guard let nsScreen = NSScreen.screen(display) else { return }
        guard appFrame.getDisplay() != nsScreen.localizedName else { return }

        let normalizedScreenFrame = nsScreen.normalizedFrame

        let origin = CGPoint(
            x: normalizedScreenFrame.midX - appFrame.width / 2.0,
            y: normalizedScreenFrame.midY - appFrame.height / 2.0
        )

        setPosition(origin)
    }

    func runWithoutAnimations(action: () -> ()) {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        let wasEnabled = appElement.enhancedUserInterface

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: false) }

        action()

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: true) }
    }
}
