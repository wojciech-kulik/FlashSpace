//
//  Integrations.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Integrations {
    private static let settings = AppDependencies.shared.settingsRepository
    private static let profilesRepository = AppDependencies.shared.profilesRepository

    static func runOnActivateIfNeeded(workspace: Workspace) {
        let script = settings.runScriptOnWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runScript(script)
    }

    static func runOnAppLaunchIfNeeded() {
        let script = settings.runScriptOnLaunch.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runScript(script)
    }

    static func runOnProfileChangeIfNeeded(profile: String) {
        let script = settings.runScriptOnProfileChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$PROFILE", with: profile)
        runScript(script)
    }

    private static func runScript(_ script: String) {
        guard settings.enableIntegrations, !script.isEmpty else { return }

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", script]
        task.launch()
    }
}
