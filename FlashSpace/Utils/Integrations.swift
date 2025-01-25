//
//  Integrations.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Integrations {
    private static let settings = AppDependencies.shared.settingsRepository

    static func runOnActivateIfNeeded(workspace: Workspace) {
        let script = settings.runScriptOnWorkspaceChange.trimmingCharacters(in: .whitespaces)

        guard settings.enableIntegrations, !script.isEmpty else { return }

        let scriptWithReplacements = script
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", scriptWithReplacements]
        task.launch()
    }

    static func runOnAppLaunchIfNeeded() {
        let script = settings.runScriptOnLaunch.trimmingCharacters(in: .whitespaces)

        guard settings.enableIntegrations, !script.isEmpty else { return }

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", script]
        task.launch()
    }
}
