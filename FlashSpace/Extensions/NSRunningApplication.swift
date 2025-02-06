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
        var windowList: CFTypeRef?
        let appElement = AXUIElementCreateApplication(processIdentifier)
        AXUIElementCopyAttributeValue(appElement, NSAccessibility.Attribute.windows as CFString, &windowList)

        guard let windows = windowList as? [AXUIElement] else {
            print("No windows found for: \(localizedName ?? "")")
            return nil
        }

        let mainWindow = windows
            .first {
                var isMain: CFTypeRef?
                AXUIElementCopyAttributeValue($0, NSAccessibility.Attribute.main as CFString, &isMain)
                return isMain as? Bool == true
            } ?? windows.first

        guard let mainWindow else {
            print("No main window found for: \(localizedName ?? "")")
            return nil
        }

        return mainWindow
    }

    var allWindows: [(window: AXUIElement, frame: CGRect)] {
        var windowList: CFTypeRef?
        let appElement = AXUIElementCreateApplication(processIdentifier)
        AXUIElementCopyAttributeValue(
            appElement,
            NSAccessibility.Attribute.windows as CFString,
            &windowList
        )

        let windows = (windowList as? [AXUIElement]) ?? []

        return windows
            .filter { $0.role == "AXWindow" }
            .compactMap { window in
                window.frame.flatMap { (window, $0) }
            }
    }

    var isMinimized: Bool {
        guard let mainWindow else { return false }

        var minimized: CFTypeRef?
        AXUIElementCopyAttributeValue(mainWindow, NSAccessibility.Attribute.minimized as CFString, &minimized)

        return minimized as? Bool == true
    }

    func raise() {
        guard let mainWindow else {
            unhide()
            return
        }

        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
    }

    func setOrigin(_ position: CGPoint) {
        guard let mainWindow else { return }

        var position = position
        let positionRef = AXValueCreate(.cgPoint, &position)
        AXUIElementSetAttributeValue(
            mainWindow,
            NSAccessibility.Attribute.position as CFString,
            positionRef as CFTypeRef
        )
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

        setOrigin(origin)
    }

    func isOnTheSameScreen(as workspace: Workspace) -> Bool {
        display == workspace.displayWithFallback
    }
}

extension [NSRunningApplication] {
    func find(_ app: MacApp?) -> NSRunningApplication? {
        guard let app else { return nil }

        return first { $0.bundleIdentifier == app.bundleIdentifier }
    }
}
