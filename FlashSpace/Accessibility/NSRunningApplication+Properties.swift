//
//  NSRunningApplication+Properties.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var frame: CGRect? { mainWindow?.frame }
    var isMinimized: Bool { mainWindow?.isMinimized == true }

    var display: DisplayName? {
        // HACK: Workaround for Orion Browser which puts
        // the main window on the main screen with size (1,1)
        if isOrion {
            allWindows
                .first { $0.frame.width > 10 && $0.frame.height > 10 }?
                .frame
                .getDisplay()
        } else {
            frame?.getDisplay()
        }
    }

    var allDisplays: Set<DisplayName> {
        allWindows
            .compactMap { $0.frame.getDisplay() }
            .asSet
    }

    var mainWindow: AXUIElement? {
        // HACK: Python app with running pygame module is causing
        // huge lags when other apps attempt to access its window
        // through the accessibility API.
        // A workaround is to simply skip this app.
        guard !isPython else { return nil }

        let appElement = AXUIElementCreateApplication(processIdentifier)
        return appElement.getAttribute(.mainWindow)
    }

    var focusedWindow: AXUIElement? {
        guard !isPython else { return nil }

        let appElement = AXUIElementCreateApplication(processIdentifier)
        return appElement.getAttribute(.focusedWindow)
    }

    var allWindows: [(window: AXUIElement, frame: CGRect)] {
        guard !isPython else { return [] }

        let appElement = AXUIElementCreateApplication(processIdentifier)
        let windows: [AXUIElement]? = appElement.getAttribute(.windows)

        return windows?
            .filter { $0.role == "AXWindow" }
            .compactMap { window in window.frame.flatMap { (window, $0) } }
            ?? []
    }

    func isOnAnyDisplay(_ displays: Set<DisplayName>) -> Bool {
        !allDisplays.isDisjoint(with: displays)
    }
}
