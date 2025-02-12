//
//  NSRunningApplication.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var toMacApp: MacApp { .init(app: self) }
    var display: DisplayName? { frame?.getDisplay() }
    var frame: CGRect? { mainWindow?.frame }
    var iconPath: String? { bundleURL?.iconPath }

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

    var isMinimized: Bool { mainWindow?.getAttribute(.minimized) == true }

    func raise() {
        guard let mainWindow else {
            unhide()
            return
        }

        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
    }

    func setPosition(_ position: CGPoint) {
        mainWindow?.setPosition(position)
    }

    func centerApp(display: DisplayName) {
        guard let appFrame = frame else {
            return print("Could not get frame for app: \(localizedName ?? "")")
        }

        guard let nsScreen = NSScreen.screens.first(where: { $0.localizedName == display }) else { return }
        guard appFrame.getDisplay() != nsScreen.localizedName else { return }

        let origin = CGPoint(
            x: nsScreen.frame.midX - appFrame.width / 2.0,
            y: nsScreen.frame.midY - appFrame.height / 2.0
        )

        setPosition(origin)
    }

    func isOnTheSameScreen(as workspace: Workspace) -> Bool {
        display == workspace.displayWithFallback
    }

    func runWithoutAnimations(action: () -> ()) {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        let wasEnabled = appElement.enhancedUserInterface

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: false) }

        action()

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: true) }
    }
}

extension [NSRunningApplication] {
    func find(_ app: MacApp?) -> NSRunningApplication? {
        guard let app else { return nil }

        return first { $0.bundleIdentifier == app.bundleIdentifier }
    }
}
