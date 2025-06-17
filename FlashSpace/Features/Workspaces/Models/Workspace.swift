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

    /// Returns the assigned display name or fallback if not connected
    var displayWithFallback: DisplayName {
        guard display != Self.dynamicDisplayName else {
            return display
        }

        guard !NSScreen.isConnected(display) else {
            return display
        }

        guard NSScreen.screens.count > 1 else {
            return NSScreen.main?.localizedName ?? ""
        }

        let settings = AppDependencies.shared.workspaceSettings
        let alternativeDisplays = settings.alternativeDisplays
            .split(separator: ";")
            .map { $0.split(separator: "=") }
            .compactMap { pair -> (source: String, target: String)? in
                guard pair.count == 2 else { return nil }

                return (String(pair[0]).trimmed, String(pair[1]).trimmed)
            }

        let alternative = alternativeDisplays
            .filter { $0.source == display }
            .first { NSScreen.isConnected($0.target) }?
            .target

        return alternative ?? NSScreen.main?.localizedName ?? ""
    }

    /// Returns all displays this workspace effectively covers
    var effectiveDisplays: Set<DisplayName> {
        if display == Self.dynamicDisplayName {
            let activeAppDisplays = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && apps.containsApp($0) }
                .compactMap(\.display)
            return Set(activeAppDisplays)
        } else {
            return Set([displayWithFallback])
        }
    }

    var isOnTheCurrentScreen: Bool {
        displayWithFallback == NSScreen.main?.localizedName
    }
}
