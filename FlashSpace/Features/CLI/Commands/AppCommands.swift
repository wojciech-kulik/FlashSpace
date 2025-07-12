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
    var floatingAppsSettings: FloatingAppsSettings { AppDependencies.shared.floatingAppsSettings }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .assignVisibleApps(let workspaceName, let showNotification):
            return assignVisibleApps(workspaceName: workspaceName, showNotification: showNotification)

        case .assignApp(let app, let workspaceName, let activate, let showNotification):
            return assignApp(
                app: app,
                workspaceName: workspaceName,
                activate: activate,
                showNotification: showNotification
            )

        case .unassignApp(let app, let showNotification):
            return unassignApp(app: app, showNotification: showNotification)

        case .hideUnassignedApps:
            workspaceManager.hideUnassignedApps()
            return CommandResponse(success: true)

        case .floatApp(let app, let showNotification):
            return floatApp(app: app, showNotification: showNotification)

        case .unfloatApp(let app, let showNotification):
            return unfloatApp(app: app, showNotification: showNotification)

        case .toggleFloatApp(let app, let showNotification):
            return toggleFloatApp(app: app, showNotification: showNotification)

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
                error: "App not found or not running. For not running apps use `unassign-app --name <bundle id>`."
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

    private func assignVisibleApps(workspaceName: String?, showNotification: Bool) -> CommandResponse {
        guard let workspaceName = workspaceName ?? workspaceManager.activeWorkspaceDetails?.name else {
            return CommandResponse(success: false, error: "No workspace selected")
        }

        guard let workspace = workspaceRepository.workspaces.first(where: { $0.name == workspaceName }) else {
            return CommandResponse(success: false, error: "Workspace not found")
        }

        let visibleApps = NSWorkspace.shared.runningApplications
            .regularVisibleApps(onDisplays: workspace.displays, excluding: floatingAppsSettings.floatingApps)

        guard !visibleApps.isEmpty else {
            return CommandResponse(
                success: false,
                error: "No visible apps found on the current display"
            )
        }

        workspaceManager.assignApps(visibleApps.map(\.toMacApp), to: workspace)

        if showNotification {
            Toast.showWith(
                icon: "square.stack.3d.up",
                message: "Assigned \(visibleApps.count) Apps(s) To \(workspace.name)",
                textColor: .positive
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
                error: "App not found or not running. For not running apps use `assign-app --name <bundle id>`."
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

    private func floatApp(app: String?, showNotification: Bool) -> CommandResponse {
        guard let app = findApp(app: app) else {
            return CommandResponse(
                success: false,
                error: "App not found or not running. For not running apps use `float-app --name <bundle id>`."
            )
        }

        floatingAppsSettings.addFloatingAppIfNeeded(app: app)

        if showNotification {
            Toast.showWith(
                icon: "macwindow.on.rectangle",
                message: "\(app.name) - Added To Floating Apps",
                textColor: .positive
            )
        }

        return CommandResponse(success: true)
    }

    private func unfloatApp(app: String?, showNotification: Bool) -> CommandResponse {
        guard let app = findApp(app: app) else {
            return CommandResponse(
                success: false,
                error: "App not found or not running. For not running apps use `unfloat-app --name <bundle id>`."
            )
        }

        guard floatingAppsSettings.floatingApps.containsApp(with: app.bundleIdentifier) else {
            return CommandResponse(success: true)
        }

        floatingAppsSettings.deleteFloatingApp(app: app)

        if let runningApp = NSWorkspace.shared.runningApplications.find(app),
           let screen = runningApp.display,
           workspaceManager.activeWorkspace[screen]?.apps.containsApp(runningApp) != true {
            runningApp.hide()
        }

        if showNotification {
            Toast.showWith(
                icon: "macwindow",
                message: "\(app.name) - Removed From Floating Apps",
                textColor: .negative
            )
        }

        return CommandResponse(success: true)
    }

    private func toggleFloatApp(app: String?, showNotification: Bool) -> CommandResponse {
        guard let macApp = findApp(app: app) else {
            return CommandResponse(
                success: false,
                error: "App not found or not running. For not running apps use `toggle-float-app --name <bundle id>`."
            )
        }

        let isFloating = floatingAppsSettings.floatingApps.containsApp(with: macApp.bundleIdentifier)

        return isFloating
            ? unfloatApp(app: app, showNotification: showNotification)
            : floatApp(app: app, showNotification: showNotification)
    }
}
