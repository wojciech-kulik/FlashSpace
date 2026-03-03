//
//  WallpaperService.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit
import AVFoundation

final class WallpaperService {
    typealias Path = String

    struct CacheEntry {
        let image: NSImage
        var timestamp: Date
    }

    private var cachedWallpapers: [Path: CacheEntry] = [:]

    func getWallpaper() -> NSImage? {
        guard let screen = NSScreen.main, let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen) else {
            return nil
        }

        if wallpaperURL.lastPathComponent == "DefaultDesktop.heic" {
            return getVideoWallpaperFromPlist() ?? loadDownsampledImage(from: wallpaperURL)
        } else if let cachedWallpaper = getCachedWallpaper(path: wallpaperURL.path) {
            return cachedWallpaper
        } else if let wallpaper = loadDownsampledImage(from: wallpaperURL) {
            addCachedWallpaper(path: wallpaperURL.path, image: wallpaper)
            return wallpaper
        }

        return nil
    }

    private func loadDownsampledImage(from url: URL) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else { return nil }

        let pointSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let maxDimension = max(pointSize.width, pointSize.height) * 0.6

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return NSImage(cgImage: downsampledImage, size: pointSize)
    }

    private func getVideoWallpaperFromPlist() -> NSImage? {
        guard let filePath = getVideoWallpaperPath() else {
            return nil
        }

        if let cachedWallpaper = getCachedWallpaper(path: filePath) {
            return cachedWallpaper
        }

        guard let firstFrame = getFirstFrame(from: URL(filePath: filePath)) else {
            return nil
        }

        addCachedWallpaper(path: filePath, image: firstFrame)
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

    private func addCachedWallpaper(path: String, image: NSImage) {
        cachedWallpapers[path] = CacheEntry(image: image, timestamp: Date())
        cleanupCacheIfNeeded()
    }

    private func getCachedWallpaper(path: String) -> NSImage? {
        guard let cacheEntry = cachedWallpapers[path] else { return nil }

        cachedWallpapers[path]?.timestamp = Date()
        return cacheEntry.image
    }

    private func cleanupCacheIfNeeded() {
        let maxCacheSize = 4

        guard cachedWallpapers.count > maxCacheSize else { return }

        let entries = Array(cachedWallpapers)
            .sorted { $0.value.timestamp > $1.value.timestamp }
            .prefix(maxCacheSize)

        cachedWallpapers = [:]

        for entry in entries {
            cachedWallpapers[entry.key] = entry.value
        }
    }
}
