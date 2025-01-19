//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class WorkspaceManager {
    init() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func showWorkspace(_ workspace: Workspace) {
        print("\n\nWORKSPACE: \(workspace.name)")
        print("----")

        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }

        let appsToHide = regularApps
            .filter { !workspace.apps.contains($0.localizedName ?? "") && !$0.isHidden }
            .filter { $0.getFrame()?.getDisplay() == workspace.display }

        let appsToShow = regularApps
            .filter { workspace.apps.contains($0.localizedName ?? "") }

        for app in appsToHide {
            print("HIDE: \(app.localizedName ?? "")")
            app.hide()
        }

        for app in appsToShow {
            app.unhide()
            focusApp(app)
            print("SHOW: \(app.localizedName ?? "")")
        }
    }

    private func focusApp(_ app: NSRunningApplication) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            NSAccessibility.Attribute.windows as CFString,
            &windowList
        )

        if result != .success {
            print("Failed to get the windows of the application.")
            return
        }

        guard let windows = windowList as? [AXUIElement], let mainWindow = windows.first else {
            print("No windows found for the application.")
            return
        }

        AXUIElementSetAttributeValue(mainWindow, NSAccessibility.Attribute.main as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
        app.activate(options: [.activateIgnoringOtherApps])
    }
}
