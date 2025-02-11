//
//  SpaceControl.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder
import SwiftUI

enum SpaceControl {
    static var isEnabled: Bool {
        AppDependencies.shared.settingsRepository.enableSpaceControl
    }

    static var isVisible: Bool { window != nil }
    static var window: NSWindow?

    static func getHotKey() -> (Shortcut, () -> ())? {
        guard isEnabled else { return nil }

        let settings = AppDependencies.shared.settingsRepository

        if let spaceControlHotKey = settings.showSpaceControl?.toShortcut() {
            return (spaceControlHotKey, show)
        }

        return nil
    }

    static func hide() {
        window?.orderOut(nil)
        window = nil
    }

    static func show() {
        guard validate() else { return }

        PermissionsManager.shared.askForScreenRecordingPermissions()

        if Self.window != nil { hide() }

        let contentView = NSHostingView(
            rootView: SpaceControlView()
        )

        let window = SpaceControlWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.delegate = window
        Self.window = window

        let animations = AppDependencies.shared.settingsRepository.enableSpaceControlAnimations

        window.contentView = contentView.addVisualEffect(material: .fullScreenUI)
        window.alphaValue = animations ? 0 : 1

        NSApp.activate()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if animations {
            window.animator().alphaValue = 1
        }
    }

    private static func validate() -> Bool {
        if AppDependencies.shared.workspaceRepository.workspaces.count < 2 {
            showOkAlert(title: "Space Control", message: "You need at least 2 workspaces to use Space Control.")
            return false
        }

        return true
    }
}
