//
//  CommandRequest.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum CommandRequest: Codable {
    case createWorkspace(CreateWorkspaceRequest)
    case deleteWorkspace(name: String)
    case updateWorkspace(UpdateWorkspaceRequest)
    case activateWorkspace(name: String?, number: Int?, clean: Bool)
    case nextWorkspace(skipEmpty: Bool, clean: Bool, loop: Bool)
    case previousWorkspace(skipEmpty: Bool, clean: Bool, loop: Bool)
    case recentWorkspace(clean: Bool)

    case assignVisibleApps(workspaceName: String?, showNotification: Bool)
    case assignApp(app: String?, workspaceName: String?, activate: Bool?, showNotification: Bool)
    case unassignApp(app: String?, showNotification: Bool)
    case hideUnassignedApps

    case floatApp(app: String?, showNotification: Bool)
    case unfloatApp(app: String?, showNotification: Bool)
    case toggleFloatApp(app: String?, showNotification: Bool)

    case focusWindow(direction: FocusDirection)
    case focusNextWindow
    case focusPreviousWindow
    case focusNextApp
    case focusPreviousApp

    case createProfile(name: String, copy: Bool, activate: Bool)
    case deleteProfile(name: String)
    case activateProfile(name: String)

    case openSpaceControl

    case listProfiles
    case listWorkspaces(withDisplay: Bool, profile: String?)
    case listApps(
        workspace: String,
        profile: String?,
        withBundleId: Bool,
        withIcon: Bool,
        onlyRunning: Bool
    )
    case listFloatingApps(withBundleId: Bool)

    case getProfile
    case getWorkspace(display: String?)
    case getApp(withWindowsCount: Bool)
    case getDisplay
}

enum FocusDirection: String, Codable {
    case left, right, up, down
}
