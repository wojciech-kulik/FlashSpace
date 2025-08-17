//
//  SpaceControl.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

enum SpaceControl {
    static var isEnabled: Bool { settings.enableSpaceControl }
    static var isVisible: Bool { window != nil }
    static var window: NSWindow?

    private static var settings: SpaceControlSettings { AppDependencies.shared.spaceControlSettings }
    private static var focusedAppBeforeShow: NSRunningApplication?

    static func getHotKey() -> (AppHotKey, () -> ())? {
        guard isEnabled else { return nil }

        if let spaceControlHotKey = settings.showSpaceControl {
            return (spaceControlHotKey, toggle)
        }

        return nil
    }

    static func toggle() {
        if isVisible {
            hide(restoreFocus: true)
        } else {
            show()
        }
    }

    static func hide(restoreFocus: Bool = false) {
        window?.orderOut(nil)
        window = nil

        if restoreFocus {
            focusedAppBeforeShow?.activate()
            focusedAppBeforeShow = nil
        }
    }

    static func show() {
        guard validate() else { return }

        PermissionsManager.shared.askForScreenRecordingPermissions()

        if window != nil { hide() }

        Task { @MainActor in
            if settings.spaceControlUpdateScreenshotsOnOpen {
                await AppDependencies.shared.workspaceScreenshotManager.updateScreenshots()
            }
            showWindow()
        }
    }

    private static func showWindow() {
        let contentView = NSHostingView(
            rootView: SpaceControlView()
        )

        // contentRect is in screen coordinates where (0,0) is bottom-left corner
        // and it is relative to the main screen.
        let window = SpaceControlWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.delegate = window
        Self.window = window

        let animations = settings.enableSpaceControlAnimations

        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = contentView.addVisualEffect(material: .fullScreenUI)

        window.alphaValue = animations ? 0 : 1

        focusedAppBeforeShow = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if animations {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().alphaValue = 1
            }
        }
    }

    private static func validate() -> Bool {
        let workspaces = AppDependencies.shared.workspaceRepository.workspaces
        let nonEmptyWorkspaces = workspaces
            .filter { !settings.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }

        if nonEmptyWorkspaces.count < 2 {
            Alert.showOkAlert(title: "Space Control", message: "You need at least 2 workspaces to use Space Control.")
            return false
        }

        return true
    }
}
