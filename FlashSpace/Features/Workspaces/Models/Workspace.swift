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
    var displays: Set<DisplayName> {
        if NSScreen.screens.count == 1 {
            return [NSScreen.main?.localizedName ?? ""]
        } else if isDynamic {
            // TODO: After disconnecting a display, the detection may not work correctly.
            // The app will have the old coordinates until it is shown again, which
            // prevents from detecting the correct display.
            //
            // The workaround is to activate the app manually to update its frame.
            return NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && apps.containsApp($0) }
                .flatMap(\.allDisplays)
                .asSet
        } else {
            return [displayManager.resolveDisplay(display)]
        }
    }

    var displayForPrint: DisplayName {
        if isDynamic,
           let mainDisplay = NSScreen.main?.localizedName,
           displays.contains(mainDisplay) {
            return mainDisplay
        }

        return isDynamic
            ? displayManager.lastActiveDisplay(from: displays)
            : displayManager.resolveDisplay(display)
    }

    var isOnTheCurrentScreen: Bool {
        guard let currentScreen = NSScreen.main?.localizedName else { return false }
        return displays.contains(currentScreen)
    }

    var isDynamic: Bool {
        AppDependencies.shared.workspaceSettings.displayMode == .dynamic
    }

    private var displayManager: DisplayManager {
        AppDependencies.shared.displayManager
    }
}
