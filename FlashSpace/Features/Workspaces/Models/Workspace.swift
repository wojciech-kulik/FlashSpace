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

    var singleDisplay: DisplayName {
        let displays = allDisplays
        if displays.count == 1 { return displays.first! }
        return AppDependencies.shared.displayManager.selectDisplay(from: displays)
    }

    var allDisplays: Set<DisplayName> {
        if NSScreen.screens.count == 1 {
            return Set([NSScreen.main?.localizedName ?? ""])
        }
        if display == Self.dynamicDisplayName {
            return Set(NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && apps.containsApp($0) }
                .compactMap(\.display)
            )
        }
        return Set([AppDependencies.shared.displayManager.resolveDisplay(display)])
    }

    /// Returns display name for user-facing contexts (shows "Dynamic" for dynamic workspaces)
    var displayForPrint: DisplayName {
        display == Self.dynamicDisplayName ? Self.dynamicDisplayName : singleDisplay
    }

    var isOnTheCurrentScreen: Bool {
        guard let currentScreen = NSScreen.main?.localizedName else { return false }
        return allDisplays.contains(currentScreen)
    }
}
