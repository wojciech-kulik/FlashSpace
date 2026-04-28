//
//  Integrations.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Integrations {
    private static let settings = AppDependencies.shared.integrationsSettings
    private static let profilesRepository = AppDependencies.shared.profilesRepository

    static func runAfterActivationIfNeeded(workspace: ActiveWorkspace) {
        let script = settings.runScriptAfterWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: workspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runScript(script, synchronous: true)
    }

    static func runOnActivateIfNeeded(workspace: ActiveWorkspace) {
        let script = settings.runScriptOnWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: workspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runScript(script, synchronous: true)
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

    private static func runScript(_ script: String, synchronous: Bool = false) {
        guard settings.enableIntegrations else { return }
        Terminal.runScript(script, synchronous: synchronous)
    }
}
