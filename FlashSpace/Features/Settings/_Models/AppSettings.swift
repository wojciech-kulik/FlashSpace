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
    var showFloatingNotifications: Bool?

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
    var focusFrontmostWindow: Bool?

    // Gestures
    var enableSwipeGestures: Bool?
    var swipeThreshold: Double?
    var swipeLeft3FingerAction: GestureAction?
    var swipeRight3FingerAction: GestureAction?
    var swipeUp3FingerAction: GestureAction?
    var swipeDown3FingerAction: GestureAction?
    var swipeLeft4FingerAction: GestureAction?
    var swipeRight4FingerAction: GestureAction?
    var swipeUp4FingerAction: GestureAction?
    var swipeDown4FingerAction: GestureAction?

    // Workspaces
    var centerCursorOnWorkspaceChange: Bool?
    var changeWorkspaceOnAppAssign: Bool?
    var enablePictureInPictureSupport: Bool?
    var switchToPreviousWorkspace: AppHotKey?
    var switchToNextWorkspace: AppHotKey?
    var switchToRecentWorkspace: AppHotKey?
    var skipEmptyWorkspacesOnSwitch: Bool?
    var assignFocusedApp: AppHotKey?
    var unassignFocusedApp: AppHotKey?
    var toggleFocusedAppAssignment: AppHotKey?
    var alternativeDisplays: String?
    var pipApps: [PipApp]?

    // Floating apps
    var floatingApps: [MacApp]?
    var floatTheFocusedApp: AppHotKey?
    var unfloatTheFocusedApp: AppHotKey?
    var toggleTheFocusedAppFloating: AppHotKey?

    // Space Control
    var enableSpaceControl: Bool?
    var showSpaceControl: AppHotKey?
    var enableSpaceControlAnimations: Bool?
    var spaceControlCurrentDisplayWorkspaces: Bool?
    var spaceControlMaxColumns: Int?
    var enableWorkspaceTransitions: Bool?
    var workspaceTransitionDuration: Double?
    var workspaceTransitionDimming: Double?

    // Integrations
    var enableIntegrations: Bool?
    var runScriptOnLaunch: String?
    var runScriptOnWorkspaceChange: String?
    var runScriptOnProfileChange: String?
}
