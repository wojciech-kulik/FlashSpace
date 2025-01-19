//
//  FileChooser.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

final class FileChooser {
    func runModalOpenPanel(allowedFileTypes: [UTType]?, directoryURL: URL?) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = allowedFileTypes ?? []
        openPanel.directoryURL = directoryURL

        return openPanel.runModal() == .OK ? openPanel.url : nil
    }

    func runModalSavePanel(allowedFileTypes: [UTType]?, defaultFileName: String?) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = allowedFileTypes ?? []
        savePanel.nameFieldStringValue = defaultFileName ?? ""

        return savePanel.runModal() == .OK ? savePanel.url : nil
    }

    @MainActor
    func runSheetModalOpenPanel(window: NSWindow, allowedFileTypes: [UTType]?, directoryURL: URL?) async -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = allowedFileTypes ?? []
        openPanel.directoryURL = directoryURL

        return await openPanel.beginSheetModal(for: window) == .OK ? openPanel.url : nil
    }

    @MainActor
    func runSheetModalSavePanel(window: NSWindow, allowedFileTypes: [UTType]?, defaultFileName: String?) async -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = allowedFileTypes ?? []
        savePanel.nameFieldStringValue = defaultFileName ?? ""

        return await savePanel.beginSheetModal(for: window) == .OK ? savePanel.url : nil
    }
}
