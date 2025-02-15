//
//  AppSettings.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

struct AppSettings: Codable {
    // General
    var checkForUpdatesAutomatically: Bool?
    var showFlashSpace: AppHotKey?

    // Menu Bar
    var showMenuBarTitle: Bool?
    var menuBarTitleTemplate: String?
    var menuBarDisplayAliases: String?

    // Focus Manager
    var enableFocusManagement: Bool?
    var centerCursorOnFocusChange: Bool?
    var focusLeft: AppHotKey?
    var focusRight: AppHotKey?
    var focusUp: AppHotKey?
    var focusDown: AppHotKey?
    var focusNextWorkspaceApp: AppHotKey?
    var focusPreviousWorkspaceApp: AppHotKey?
    var focusNextWorkspaceWindow: AppHotKey?
    var focusPreviousWorkspaceWindow: AppHotKey?

    // Workspaces
    var centerCursorOnWorkspaceChange: Bool?
    var switchToPreviousWorkspace: AppHotKey?
    var switchToNextWorkspace: AppHotKey?
    var switchToRecentWorkspace: AppHotKey?
    var assignFocusedApp: AppHotKey?
    var unassignFocusedApp: AppHotKey?
    var showFloatingNotifications: Bool?
    var changeWorkspaceOnAppAssign: Bool?
    var enablePictureInPictureSupport: Bool?

    // Floating apps
    var floatingApps: [MacApp]?
    var floatTheFocusedApp: AppHotKey?
    var unfloatTheFocusedApp: AppHotKey?

    // Space Control
    var enableSpaceControl: Bool?
    var showSpaceControl: AppHotKey?
    var enableSpaceControlAnimations: Bool?
    var spaceControlCurrentDisplayWorkspaces: Bool?

    // Integrations
    var enableIntegrations: Bool?
    var runScriptOnWorkspaceChange: String?
    var runScriptOnLaunch: String?
    var runScriptOnProfileChange: String?
}
