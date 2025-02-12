//
//  PictureInPictureManager.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class PictureInPictureManager {
    typealias AXWindow = AXUIElement

    private var hiddenWindows: [NSRunningApplication: [AXWindow]] = [:]
    private var capturedFrame: [AXWindow: CGRect] = [:]

    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
        setupSignalHandlers()
    }

    func restoreAppIfNeeded(app: NSRunningApplication) {
        guard settingsRepository.enablePictureInPictureSupport else { return }

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
        guard settingsRepository.enablePictureInPictureSupport,
              app.supportsPictureInPicture else { return }

        restoreFromCornerNonPipWindows(app: app)
    }

    func hidePipAppIfNeeded(app: NSRunningApplication) -> Bool {
        guard settingsRepository.enablePictureInPictureSupport,
              app.supportsPictureInPicture,
              app.isPictureInPictureActive
        else { return false }

        guard hiddenWindows[app] == nil else { return true }

        return hideInCornerNonPipWindows(app: app)
    }

    private func restoreFromCornerNonPipWindows(app: NSRunningApplication) {
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
        guard let appScreen = NSScreen.screens.first(where: { $0.localizedName == app.display }) else {
            return nil
        }

        // Screen left-bottom = (0, 0)
        // Window origin is in the top-left corner
        // Window position is set relative to the top-left screen corner

        let appFrame = app.frame
        let screenFrame = appScreen.frame
        let leftCorner = CGPoint(x: screenFrame.minX, y: screenFrame.minY)
        let rightCorner = CGPoint(x: screenFrame.maxX, y: screenFrame.minY)
        let leftSide = leftCorner.applying(
            CGAffineTransform(translationX: -30.0, y: 30.0)
        )
        let leftBottomSide = leftCorner.applying(
            CGAffineTransform(translationX: 30.0, y: -30.0)
        )
        let rightSide = rightCorner.applying(
            CGAffineTransform(translationX: 30.0, y: 30.0)
        )
        let rightBottomSide = rightCorner.applying(
            CGAffineTransform(translationX: -30.0, y: -30.0)
        )

        let allScreens = NSScreen.screens.map(\.frame)
        let isLeftCornerUsed = allScreens.contains(where: { $0.contains(leftSide) || $0.contains(leftBottomSide) })
        let isRightCornerUsed = allScreens.contains(where: { $0.contains(rightSide) || $0.contains(rightBottomSide) })

        if isLeftCornerUsed || !isRightCornerUsed || appFrame == nil {
            // right corner
            return CGPoint(x: screenFrame.maxX - 30.0, y: screenFrame.maxY - 30.0)
        } else {
            // left corner
            let appFrame = appFrame ?? .zero
            return CGPoint(
                x: screenFrame.minX + 30.0 - appFrame.width,
                y: screenFrame.maxY - 30.0
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
