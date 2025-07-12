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
    static let dynamicDisplayName = "Dynamic"

    var displays: Set<DisplayName> {
        guard NSScreen.screens.count > 1 else {
            return Set([NSScreen.main?.localizedName ?? ""])
        }

        guard display == Self.dynamicDisplayName else {
            return [displayManager.resolveDisplay(display)]
        }

        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && apps.containsApp($0) }
            .flatMap(\.allDisplays)
            .asSet
    }

    var mainDisplay: DisplayName {
        let workspaceDisplays = displays

        return workspaceDisplays.count == 1
            ? workspaceDisplays.first!
            : displayManager.lastActiveDisplay(from: workspaceDisplays)
    }

    /// Returns display name for user-facing contexts (shows "Dynamic" for dynamic workspaces)
    var displayForPrint: DisplayName {
        display == Self.dynamicDisplayName ? display : displayManager.resolveDisplay(display)
    }

    var isOnTheCurrentScreen: Bool {
        guard let currentScreen = NSScreen.main?.localizedName else { return false }
        return displays.contains(currentScreen)
    }

    private var displayManager: DisplayManager {
        AppDependencies.shared.displayManager
    }
}
