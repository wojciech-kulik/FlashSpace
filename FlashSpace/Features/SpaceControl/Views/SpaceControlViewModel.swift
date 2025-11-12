//
//  SpaceControlViewModel.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import AVFoundation
import Combine
import SwiftUI

struct SpaceControlWorkspace {
    let index: Int
    let name: String
    let symbol: String
    let screenshotData: Data?
    let isActive: Bool
    let originalWorkspace: Workspace
}

final class SpaceControlViewModel: ObservableObject {
    @Published var isVisible = false

    @Published private(set) var workspaces: [SpaceControlWorkspace] = []
    @Published private(set) var numberOfRows = 0
    @Published private(set) var numberOfColumns = 0
    @Published private(set) var tileSize: CGSize = .zero

    var wallpaperImage: NSImage? {
        if let screen = NSScreen.main,
           let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen) {
            if wallpaperURL.lastPathComponent == "DefaultDesktop.heic" {
                return getVideoWallpaperFromPlist() ?? NSImage(contentsOf: wallpaperURL)
            } else {
                return NSImage(contentsOf: wallpaperURL)
            }
        }

        return nil
    }

    private var cachedWallpaper: (path: String, image: NSImage)?
    private var cancellables = Set<AnyCancellable>()

    private let settings = AppDependencies.shared.spaceControlSettings
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let screenshotManager = AppDependencies.shared.workspaceScreenshotManager
    private let displayManager = AppDependencies.shared.displayManager

    init() {
        refresh()

        self.isVisible = !settings.enableSpaceControlTilesAnimations

        NotificationCenter.default
            .publisher(for: .spaceControlArrowDown)
            .compactMap { $0.object as? RawKeyCode }
            .sink { [weak self] in self?.handleArrowKey($0) }
            .store(in: &cancellables)
    }

    func onWorkspaceTap(_ workspace: SpaceControlWorkspace) {
        workspaceManager.activateWorkspace(workspace.originalWorkspace, setFocus: true)
    }

    func refresh() {
        let activeWorkspaceIds = workspaceManager.activeWorkspace.map(\.value.id).asSet
        let mainDisplay = NSScreen.main?.localizedName ?? ""

        var sourceWorkspaces = workspaceRepository.workspaces
            .filter { !settings.spaceControlCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }

        if settings.spaceControlHideEmptyWorkspaces {
            sourceWorkspaces = sourceWorkspaces.skipWithoutRunningApps()
        }

        workspaces = Array(
            sourceWorkspaces
                .prefix(35)
                .enumerated()
                .map {
                    let workspace = $0.element
                    let displayName = settings.spaceControlCurrentDisplayWorkspaces
                        ? mainDisplay
                        : self.mainDisplay(for: workspace)
                    let key = WorkspaceScreenshotManager.ScreenshotKey(
                        displayName: displayName,
                        workspaceID: workspace.id
                    )
                    return SpaceControlWorkspace(
                        index: $0.offset,
                        name: workspace.name,
                        symbol: workspace.symbolIconName ?? .defaultIconSymbol,
                        screenshotData: screenshotManager.screenshots[key],
                        isActive: activeWorkspaceIds.contains(workspace.id),
                        originalWorkspace: workspace
                    )
                }
        )
        calculateColsAndRows(workspaces.count)
        calculateTileSize()
    }

    private func mainDisplay(for workspace: Workspace) -> DisplayName {
        let workspaceDisplays = workspace.displays

        return workspaceDisplays.count == 1
            ? workspaceDisplays.first!
            : displayManager.lastActiveDisplay(from: workspaceDisplays)
    }

    private func calculateColsAndRows(_ workspaceCount: Int) {
        let calculateRows = { (columns: Int) -> Int in
            Int(ceil(Double(workspaceCount) / Double(columns)))
        }

        if settings.spaceControlNumberOfColumns > 0 {
            numberOfColumns = min(settings.spaceControlNumberOfColumns, workspaceCount)
            numberOfRows = calculateRows(numberOfColumns)

            if numberOfRows > 6 {
                numberOfColumns = Int(ceil(Double(workspaceCount) / 6.0))
                numberOfRows = calculateRows(numberOfColumns)
            }

            return
        }

        let initialNumberOfColumns = 4
        let maxRows = 4
        let maxColumns = 7

        var numberOfColumns = min(initialNumberOfColumns, workspaceCount)
        var numberOfRows = calculateRows(numberOfColumns)

        while numberOfRows > maxRows, numberOfColumns < maxColumns {
            numberOfColumns += 1
            numberOfRows = calculateRows(numberOfColumns)
        }

        self.numberOfColumns = numberOfColumns
        self.numberOfRows = numberOfRows
    }

    private func calculateTileSize() {
        let screenFrame = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 3024, height: 1964)

        let width = screenFrame.width / CGFloat(numberOfColumns) - 120.0
        let height = screenFrame.height / CGFloat(numberOfRows) - 120.0

        let firstScreenshot = workspaces
            .lazy
            .compactMap { $0.screenshotData.flatMap(NSImage.init(data:)) }
            .first

        guard let firstScreenshot else {
            let scale = screenFrame.width / screenFrame.height
            tileSize = CGSize(
                width: min(width, height * scale),
                height: min(height, width / scale)
            )
            return
        }

        let tileRatio = width / height
        let screenshotRatio = firstScreenshot.size.width / firstScreenshot.size.height

        if tileRatio > screenshotRatio {
            // Tile is wider than screenshot, adjust width
            let scaledWidth = height * screenshotRatio
            tileSize = CGSize(width: scaledWidth, height: height)
        } else {
            // Tile is taller than screenshot, adjust height
            let scaledHeight = width / screenshotRatio
            tileSize = CGSize(width: width, height: scaledHeight)
        }
    }

    private func handleArrowKey(_ keyCode: RawKeyCode) {
        let activeWorkspaceIndex = workspaces.firstIndex {
            $0.isActive && $0.originalWorkspace.isOnTheCurrentScreen
        }
        guard let activeWorkspaceIndex else { return }

        let workspace: Workspace? = switch KeyCodesMap.toString[keyCode] {
        case "down":
            workspaces[safe: activeWorkspaceIndex + numberOfColumns]?.originalWorkspace
        case "up":
            workspaces[safe: activeWorkspaceIndex - numberOfColumns]?.originalWorkspace
        case "right":
            workspaces[safe: (activeWorkspaceIndex + 1) % workspaces.count]?.originalWorkspace
        case "left":
            workspaces[
                safe: activeWorkspaceIndex == 0
                    ? workspaces.count - 1
                    : activeWorkspaceIndex - 1
            ]?.originalWorkspace
        default:
            nil
        }

        if let workspace {
            SpaceControl.hide()
            workspaceManager.activateWorkspace(workspace, setFocus: true)
        }
    }

    private func getVideoWallpaperFromPlist() -> NSImage? {
        guard let filePath = getVideoWallpaperPath() else {
            return nil
        }

        if let cachedWallpaper, cachedWallpaper.path == filePath {
            return cachedWallpaper.image
        }

        guard let firstFrame = getFirstFrame(from: URL(filePath: filePath)) else {
            return nil
        }

        cachedWallpaper = (path: filePath, image: firstFrame)
        return firstFrame
    }

    private func getVideoWallpaperPath() -> String? {
        do {
            let infoPlist = "~/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
            let plistURL = URL(fileURLWithPath: infoPlist)
            let data = try Data(contentsOf: plistURL)

            guard let plistDictionary = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: AnyObject] else { return nil }

            guard
                let allDisplays = plistDictionary["AllSpacesAndDisplays"] as? NSDictionary,
                let idle = allDisplays["Desktop"] as? NSDictionary,
                let content = idle["Content"] as? NSDictionary,
                let choices = content["Choices"] as? NSArray,
                choices.count > 0,
                let choicesDict = choices[0] as? NSDictionary,
                let encodedData = choicesDict["Configuration"] as? Data,
                encodedData.isNotEmpty else {
                return nil
            }

            guard let configurationPlist = try PropertyListSerialization.propertyList(
                from: encodedData,
                options: [],
                format: nil
            ) as? [String: AnyObject] else { return nil }

            guard let assetID = configurationPlist["assetID"] as? String else {
                return nil
            }

            return "~/Library/Application Support/com.apple.wallpaper/aerials/videos/\(assetID).mov"
        } catch {
            Logger.log(error)
            return nil
        }
    }

    private func getFirstFrame(from url: URL) -> NSImage? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            Logger.log("Wallpaper video file does not exist at path: \(url.path)")
            return nil
        }

        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return NSImage(cgImage: cgImage, size: .zero)
        } catch {
            Logger.log(error)
            return nil
        }
    }
}
