//
//  WorkspaceScreenshotManager.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import CoreGraphics
import ScreenCaptureKit
import SwiftUI

final class WorkspaceScreenshotManager {
    typealias ImageData = Data

    struct ScreenshotKey: Hashable {
        let displayName: DisplayName
        let workspaceID: WorkspaceID
    }

    private(set) var screenshots: [ScreenshotKey: ImageData] = [:]
    private var cancellables = Set<AnyCancellable>()

    private let spaceControlSettings: SpaceControlSettings
    private let workspaceManager: WorkspaceManager
    private let lock = NSLock()

    init(
        spaceControlSettings: SpaceControlSettings,
        workspaceManager: WorkspaceManager
    ) {
        self.spaceControlSettings = spaceControlSettings
        self.workspaceManager = workspaceManager

        observe()
    }

    @MainActor
    func updateScreenshots() async {
        let activeWorkspaces = workspaceManager.activeWorkspace
            .filter { !spaceControlSettings.spaceControlCurrentDisplayWorkspaces || $0.value.isOnTheCurrentScreen }

        for (display, workspace) in activeWorkspaces {
            await captureWorkspace(workspace, displayName: display)
        }
    }

    func captureWorkspace(_ workspace: Workspace, displayName: DisplayName) async {
        let shouldCapture = await MainActor.run {
            !SpaceControl.isVisible &&
                SpaceControl.isEnabled &&
                PermissionsManager.shared.checkForScreenRecordingPermissions()
        }

        guard shouldCapture else { return }

        do {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let display = await MainActor.run {
                availableContent.displays.first { $0.frame.getDisplay() == displayName }
            }

            guard let display else { return }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.captureResolution = .best
            config.width = Int(display.frame.width)
            config.height = Int(display.frame.height)
            config.showsCursor = false

            let screenshot = try await SCScreenshotManager.captureSampleBuffer(
                contentFilter: filter,
                configuration: config
            )

            if let image = imageFromSampleBuffer(screenshot) {
                let key = ScreenshotKey(
                    displayName: displayName,
                    workspaceID: workspace.id
                )
                saveScreenshot(image, workspace: workspace, key: key)
            }
        } catch {
            Logger.log(error)
        }
    }

    private func imageFromSampleBuffer(_ buffer: CMSampleBuffer) -> NSImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let representation = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: representation.size)
        nsImage.addRepresentation(representation)

        return nsImage
    }

    private func saveScreenshot(_ image: NSImage, workspace: Workspace, key: ScreenshotKey) {
        let newWidth: CGFloat = 1900.0
        let newHeight = (newWidth / image.size.width) * image.size.height
        let newSize = CGSize(width: newWidth, height: newHeight)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(newWidth),
            pixelsHigh: Int(newHeight),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }

        lock.lock()
        screenshots[key] = jpegData
        lock.unlock()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .workspaceTransitionFinished)
            .compactMap { $0.object as? Workspace }
            .sink { [weak self] workspace in
                for display in workspace.displays {
                    Task.detached { [weak self] in
                        await self?.captureWorkspace(workspace, displayName: display)
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in
                self?.screenshots = [:]
            }
            .store(in: &cancellables)
    }
}
