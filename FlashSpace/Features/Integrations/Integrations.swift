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
    private static let workspaceScriptsQueue = DispatchQueue(label: "pl.wojciechkulik.FlashSpace.integrations")

    static func runAfterActivationIfNeeded(workspace: ActiveWorkspace) {
        let script = settings.runScriptAfterWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: workspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runWorkspaceScript(script, waitForCompletion: false)
    }

    static func runOnActivateIfNeeded(workspace: ActiveWorkspace) {
        let script = settings.runScriptOnWorkspaceChange.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: workspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: workspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: workspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
        runWorkspaceScript(script, waitForCompletion: true)
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
        guard settings.enableIntegrations else { return }
        Terminal.runScript(script)
    }

    /// Workspace change scripts are run on a serial queue to preserve their order.
    ///
    /// The script run before the workspace change must be completed before apps
    /// are shown and hidden, so the caller waits for it. The one run after the change
    /// doesn't block the main thread, because it would delay processing focus change
    /// notifications sent by the system. Those notifications are used to detect focus
    /// changes made by the user and delaying them makes FlashSpace treat its own
    /// temporary focus changes as the user ones.
    private static func runWorkspaceScript(_ script: String, waitForCompletion: Bool) {
        guard settings.enableIntegrations, !script.isEmpty else { return }

        if waitForCompletion {
            workspaceScriptsQueue.sync { Terminal.runScript(script, synchronous: true) }
        } else {
            workspaceScriptsQueue.async { Terminal.runScript(script, synchronous: true) }
        }
    }
}
