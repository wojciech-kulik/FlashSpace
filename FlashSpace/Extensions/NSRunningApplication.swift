//
//  NSRunningApplication.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var toMacApp: MacApp { .init(app: self) }
    var iconPath: String? { bundleURL?.iconPath }
}

extension [NSRunningApplication] {
    func find(_ app: MacApp?) -> NSRunningApplication? {
        guard let app else { return nil }

        return first { $0.bundleIdentifier == app.bundleIdentifier }
    }

    func findFirstMatch(with apps: [MacApp]) -> NSRunningApplication? {
        let bundleIdentifiers = Set(apps.map(\.bundleIdentifier))

        return first { bundleIdentifiers.contains($0.bundleIdentifier ?? "") }
    }

    func excludeFloatingAppsOnDifferentScreen() -> [NSRunningApplication] {
        let activeWorkspace = AppDependencies.shared.workspaceManager.activeWorkspace[NSScreen.main?.localizedName ?? ""]
        let floatingApps = AppDependencies.shared.floatingAppsSettings.floatingApps

        guard let activeWorkspace else { return self }

        return filter { !floatingApps.containsApp($0) || $0.isOnTheSameScreen(as: activeWorkspace) }
    }
}
