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

    private weak static var viewModel: SpaceControlViewModel?
    private static var transitionInProgress = false

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
        guard !transitionInProgress else { return }

        let hideAction = {
            window?.orderOut(nil)
            window = nil

            if restoreFocus {
                focusedAppBeforeShow?.activate()
                focusedAppBeforeShow = nil
            }
            viewModel = nil
            transitionInProgress = false
        }

        if settings.enableSpaceControlAnimations {
            fadeOutWindow(completion: hideAction)
        } else {
            hideAction()
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
        guard !transitionInProgress else { return }

        let animations = settings.enableSpaceControlAnimations
        let viewModel = SpaceControlViewModel()
        let contentView = NSHostingView(
            rootView: SpaceControlView(viewModel: viewModel)
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
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = contentView.addVisualEffect(material: .fullScreenUI)
        window.alphaValue = animations ? 0 : 1

        Self.window = window
        Self.viewModel = viewModel

        focusedAppBeforeShow = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if animations { fadeInWindow() }
    }

    private static func fadeInWindow() {
        transitionInProgress = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window?.animator().alphaValue = 1
        }, completionHandler: {
            transitionInProgress = false
        })
    }

    private static func fadeOutWindow(completion: @escaping () -> ()) {
        transitionInProgress = true

        if settings.enableSpaceControlTilesAnimations {
            viewModel?.isVisible = false
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window?.animator().alphaValue = 0
        }, completionHandler: {
            completion()
            transitionInProgress = false
        })
    }

    private static func validate() -> Bool {
        var workspaces = AppDependencies.shared.workspaceRepository.workspaces
            .filter { !settings.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }

        if settings.spaceControlHideEmptyWorkspaces {
            workspaces = workspaces.skipWithoutRunningApps()
        }

        if workspaces.isEmpty {
            Alert.showOkAlert(title: "Space Control", message: "You need at least 1 workspace to use Space Control.")
            return false
        }

        return true
    }
}
