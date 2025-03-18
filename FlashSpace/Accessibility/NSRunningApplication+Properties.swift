//
//  NSRunningApplication+Properties.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var display: DisplayName? {
        // HACK: Workaround for Orion Browser which puts
        // the main window on the main screen with size (1,1)
        if bundleIdentifier == "com.kagi.kagimacOS" {
            allWindows
                .first { $0.frame.width > 10 && $0.frame.height > 10 }?
                .frame
                .getDisplay()
        } else {
            frame?.getDisplay()
        }
    }

    var frame: CGRect? { mainWindow?.frame }
    var isMinimized: Bool { mainWindow?.isMinimized == true }

    var mainWindow: AXUIElement? {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        return appElement.getAttribute(.mainWindow)
    }

    var focusedWindow: AXUIElement? {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        return appElement.getAttribute(.focusedWindow)
    }

    var allWindows: [(window: AXUIElement, frame: CGRect)] {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        let windows: [AXUIElement]? = appElement.getAttribute(.windows)

        return windows?
            .filter { $0.role == "AXWindow" }
            .compactMap { window in window.frame.flatMap { (window, $0) } }
            ?? []
    }

    func isOnTheSameScreen(as workspace: Workspace) -> Bool {
        display == workspace.displayWithFallback
    }
}
