//
//  Workspace.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

typealias WorkspaceID = UUID

struct Workspace: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case display
        case activateShortcut = "shortcut"
        case assignAppShortcut
        case apps
        case appToFocus
        case symbolIconName
    }

    var id: WorkspaceID
    var name: String
    var display: DisplayName
    var activateShortcut: AppHotKey?
    var assignAppShortcut: AppHotKey?
    var apps: [MacApp]
    var appToFocus: MacApp?
    var symbolIconName: String?
}

extension Workspace {
    /// If only one display is connected, fallbacks to the main display
    var displayWithFallback: DisplayName {
        NSScreen.screens.count > 1
            ? display
            : NSScreen.main?.localizedName ?? ""
    }

    var isOnTheCurrentScreen: Bool {
        displayWithFallback == NSScreen.main?.localizedName
    }
}
