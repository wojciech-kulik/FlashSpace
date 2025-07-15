//
//  PictureInPictureManager.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class PictureInPictureManager {
    typealias AXWindow = AXUIElement

    private var hiddenWindows: [NSRunningApplication: [AXWindow]] = [:]
    private var capturedFrame: [AXWindow: CGRect] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var windowFocusObserver: AXObserver?

    private let settings: WorkspaceSettings

    init(settingsRepository: SettingsRepository) {
        self.settings = settingsRepository.workspaceSettings
        setupSignalHandlers()
        observePipFocusChangeNotification()
    }

    func restoreAppIfNeeded(app: NSRunningApplication) {
        guard settings.enablePictureInPictureSupport else { return }

        if hiddenWindows.keys.contains(app) {
            restoreFromCornerNonPipWindows(app: app)
        }
    }

    func restoreAllWindows() {
        for app in hiddenWindows.keys {
            showPipAppIfNeeded(app: app)
        }
    }

    func showPipAppIfNeeded(app: NSRunningApplication) {
        guard settings.enablePictureInPictureSupport,
              app.supportsPictureInPicture else { return }

        restoreFromCornerNonPipWindows(app: app)
    }

    func hidePipAppIfNeeded(app: NSRunningApplication) -> Bool {
        guard settings.enablePictureInPictureSupport,
              app.supportsPictureInPicture,
              app.isPictureInPictureActive
        else { return false }

        guard hiddenWindows[app] == nil else { return true }

        guard settings.displayMode == .static || app.allDisplays.count <= 1 else {
            // pip is not supported for multi-display apps
            return false
        }

        return hideInCornerNonPipWindows(app: app)
    }

    private func observePipFocusChangeNotification() {
        NotificationCenter.default
            .publisher(for: .pipFocusChanged)
            .sink { [weak self] _ in self?.restorePipWorkspace() }
            .store(in: &cancellables)
    }

    private func restorePipWorkspace() {
        guard let app = hiddenWindows.keys.first(where: { !$0.isPictureInPictureActive }) else { return }

        restoreAllWindows()

        let workspaceRepository = AppDependencies.shared.workspaceRepository
        let workspaceManager = AppDependencies.shared.workspaceManager
        let workspace = workspaceRepository.workspaces.first { $0.apps.containsApp(app) }

        guard let workspace else { return }

        windowFocusObserver = nil
        workspaceManager.activateWorkspace(workspace, setFocus: false)
    }

    private func restoreFromCornerNonPipWindows(app: NSRunningApplication) {
        windowFocusObserver = nil

        app.runWithoutAnimations {
            for window in hiddenWindows[app] ?? [] {
                if let previousFrame = capturedFrame[window] {
                    window.setPosition(previousFrame.origin)
                    capturedFrame.removeValue(forKey: window)
                }
            }
        }

        hiddenWindows.removeValue(forKey: app)
    }

    private func hideInCornerNonPipWindows(app: NSRunningApplication) -> Bool {
        guard let screenCorner = findScreenCorner(app: app) else { return false }

        let nonPipWindows = app.allWindows
            .map(\.window)
            .filter { !$0.isPictureInPicture(bundleId: app.bundleIdentifier) }

        if nonPipWindows.isNotEmpty { observePipApp(app) }

        app.runWithoutAnimations {
            for window in nonPipWindows {
                if let windowFrame = window.frame, screenCorner != windowFrame.origin {
                    capturedFrame[window] = windowFrame
                    window.setPosition(screenCorner)
                }
            }
        }
        hiddenWindows[app] = nonPipWindows

        return true
    }

    private func findScreenCorner(app: NSRunningApplication) -> CGPoint? {
        guard let appScreen = NSScreen.screen(app.display) else {
            return nil
        }

        // Screen origin (0,0) is in the bottom-left corner, y-axis is pointing up
        // Window origin (0,0) is in the top-left corner, y-axis is pointing down
        // E.g. To place a window in the bottom-right corner of the screen
        // we need to set window origin to:
        // (screen.maxX - window.width, screen.maxY - window.height).

        let testOffset: CGFloat = 30.0
        let cornerOffset = CGFloat(settings.pipScreenCornerOffset)
        let appFrame = app.frame
        let screenFrame = appScreen.frame
        let leftCorner = CGPoint(x: screenFrame.minX, y: screenFrame.minY)
        let rightCorner = CGPoint(x: screenFrame.maxX, y: screenFrame.minY)
        let leftSide = leftCorner.applying(
            CGAffineTransform(translationX: -testOffset, y: testOffset)
        )
        let leftBottomSide = leftCorner.applying(
            CGAffineTransform(translationX: testOffset, y: -testOffset)
        )
        let rightSide = rightCorner.applying(
            CGAffineTransform(translationX: testOffset, y: testOffset)
        )
        let rightBottomSide = rightCorner.applying(
            CGAffineTransform(translationX: -testOffset, y: -testOffset)
        )

        let allScreens = NSScreen.screens.map(\.frame)
        let isLeftCornerUsed = allScreens.contains(where: { $0.contains(leftSide) || $0.contains(leftBottomSide) })
        let isRightCornerUsed = allScreens.contains(where: { $0.contains(rightSide) || $0.contains(rightBottomSide) })

        if isLeftCornerUsed || !isRightCornerUsed || appFrame == nil {
            // right corner (window coordinates)
            return CGPoint(
                x: screenFrame.maxX - cornerOffset,
                y: screenFrame.maxY - cornerOffset
            )
        } else {
            // left corner (window coordinates)
            let appFrame = appFrame ?? .zero
            return CGPoint(
                x: screenFrame.minX + cornerOffset - appFrame.width,
                y: screenFrame.maxY - cornerOffset
            )
        }
    }

    private func setupSignalHandlers() {
        for code in [SIGTERM, SIGINT] {
            signal(code) {
                AppDependencies.shared.pictureInPictureManager.restoreAllWindows()
                exit($0)
            }
        }
    }

    private func observePipApp(_ app: NSRunningApplication) {
        guard settings.switchWorkspaceWhenPipCloses else { return }

        let callback: AXObserverCallback = { _, _, _, _ in
            NotificationCenter.default.post(name: .pipFocusChanged, object: nil)
        }

        let result = AXObserverCreate(app.processIdentifier, callback, &windowFocusObserver)

        guard result == .success, let observer = windowFocusObserver else { return }

        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        AXObserverAddNotification(observer, appRef, kAXFocusedWindowChangedNotification as CFString, nil)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    // MARK: - Alternative solution by minimizing windows (animation)
    private func deminimizeAllWindows(app: NSRunningApplication) {
        for window in app.allWindows.map(\.window) {
            window.minimize(false)
        }
    }

    private func minimizeNonPipWindows(app: NSRunningApplication) {
        app.allWindows
            .map(\.window)
            .filter { !$0.isPictureInPicture(bundleId: app.bundleIdentifier) }
            .forEach { $0.minimize(true) }
    }
}
