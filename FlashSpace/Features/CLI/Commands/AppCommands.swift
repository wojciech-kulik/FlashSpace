//
//  AppCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class AppCommands: CommandExecutor {
    var workspaceManager: WorkspaceManager { AppDependencies.shared.workspaceManager }
    var workspaceRepository: WorkspaceRepository { AppDependencies.shared.workspaceRepository }
    var settings: WorkspaceSettings { AppDependencies.shared.workspaceSettings }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .assignApp(let app, let workspaceName, let activate, let showNotification):
            return assignApp(
                app: app,
                workspaceName: workspaceName,
                activate: activate,
                showNotification: showNotification
            )

        case .unassignApp(let app, let showNotification):
            return unassignApp(app: app, showNotification: showNotification)

        default:
            return nil
        }
    }

    private func findApp(app: String?) -> MacApp? {
        guard let app else { return NSWorkspace.shared.frontmostApplication?.toMacApp }

        let foundApp = NSWorkspace.shared.runningApplications
            .first { $0.localizedName == app }?
            .toMacApp

        if foundApp == nil, let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) {
            return MacApp(
                name: appUrl.bundle?.localizedAppName ?? "",
                bundleIdentifier: app,
                iconPath: appUrl.iconPath
            )
        }

        return foundApp
    }

    private func unassignApp(app: String?, showNotification: Bool) -> CommandResponse {
        guard let app = findApp(app: app) else {
            return CommandResponse(
                success: false,
                error: "App not found or not running. For not running apps use --unassign-app <bundle id>."
            )
        }

        workspaceRepository.deleteAppFromAllWorkspaces(app: app)
        NSWorkspace.shared.runningApplications.find(app)?.hide()
        NotificationCenter.default.post(name: .appsListChanged, object: nil)

        if showNotification {
            Toast.showWith(
                icon: "square.stack.3d.up.slash",
                message: "\(app.name) - Removed From Workspaces",
                textColor: .negative
            )
        }

        return CommandResponse(success: true)
    }

    private func assignApp(
        app: String?,
        workspaceName: String?,
        activate: Bool?,
        showNotification: Bool
    ) -> CommandResponse {
        guard let workspaceName = workspaceName ?? workspaceManager.activeWorkspaceDetails?.name else {
            return CommandResponse(success: false, error: "No workspace selected")
        }

        guard let workspace = workspaceRepository.workspaces.first(where: { $0.name == workspaceName }) else {
            return CommandResponse(success: false, error: "Workspace not found")
        }

        guard let app = findApp(app: app) else {
            return CommandResponse(
                success: false,
                error: "App not found or not running. For not running apps use --assign-app <bundle id>."
            )
        }

        let previousSetting = settings.changeWorkspaceOnAppAssign
        if let activate {
            settings.changeWorkspaceOnAppAssign = activate
        }
        workspaceManager.assignApp(app, to: workspace)
        if activate != nil {
            settings.changeWorkspaceOnAppAssign = previousSetting
        }

        if showNotification {
            Toast.showWith(
                icon: "square.stack.3d.up",
                message: "\(app.name) - Assigned To \(workspace.name)",
                textColor: .positive
            )
        }

        return CommandResponse(success: true)
    }
}
