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

    static func runOnActivateIfNeeded(workspace: ActiveWorkspace) {
        let script = settings.runScriptOnWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: workspace.number ?? "")
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

        let shell = getDefaultShell() ?? "/bin/sh"
        let task = Process()
        task.launchPath = shell
        task.arguments = ["-c", script]
        task.launch()
    }

    private static func getDefaultShell() -> String? {
        guard let pw = getpwuid(getuid()), let shellCString = pw.pointee.pw_shell else { return nil }

        return String(cString: shellCString)
    }
}
