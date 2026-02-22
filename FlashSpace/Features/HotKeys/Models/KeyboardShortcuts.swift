//
//  KeyboardShortcuts.swift
//
//  Created by Wojciech Kulik on 21/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import KeyboardShortcuts

typealias HotKeyName = KeyboardShortcuts.Name
typealias Shortcut = KeyboardShortcuts.Name.Shortcut

struct RecordedHotKey {
    let name: KeyboardShortcuts.Name
    let hotKey: AppHotKey
    let action: () -> ()
}

extension HotKeyName {
    static let inactiveShortcut = Self("inactiveShortcut")

    static let showFlashSpace = Self("showFlashSpace")
    static let toggleFlashSpace = Self("toggleFlashSpace")
    static let toggleSpaceControl = Self("toggleSpaceControl")
    static let pauseResumeFlashSpace = Self("pauseResumeFlashSpace")

    static let assignVisibleApps = Self("assignVisibleApps")
    static let assignFocusedApp = Self("assignFocusedApp")
    static let unassignFocusedApp = Self("unassignFocusedApp")
    static let toggleFocusedAppAssignment = Self("toggleFocusedAppAssignment")
    static let showUnassignedApps = Self("showUnassignedApps")
    static let hideUnassignedApps = Self("hideUnassignedApps")
    static let hideAllApps = Self("hideAllApps")
    static let nextWorkspace = Self("nextWorkspace")
    static let previousWorkspace = Self("previousWorkspace")
    static let recentWorkspace = Self("recentWorkspace")

    static let floatFocusedApp = Self("floatFocusedApp")
    static let unfloatFocusedApp = Self("unfloatFocusedApp")
    static let toggleFocusedAppFloating = Self("toggleFocusedAppFloating")

    static let focusLeftApp = Self("focusLeftApp")
    static let focusRightApp = Self("focusRightApp")
    static let focusUpApp = Self("focusUpApp")
    static let focusDownApp = Self("focusDownApp")
    static let focusNextApp = Self("focusNextApp")
    static let focusPreviousApp = Self("focusPreviousApp")
    static let focusNextWindow = Self("focusNextWindow")
    static let focusPreviousWindow = Self("focusPreviousWindow")

    static let nextProfile = Self("nextProfile")
    static let previousProfile = Self("previousProfile")

    static func assignAppToWorkspace(_ workspaceId: WorkspaceID) -> Self {
        Self("assignAppToWorkspace_\(workspaceId)")
    }

    static func activateWorkspace(_ workspaceId: WorkspaceID) -> Self {
        Self("activateWorkspace_\(workspaceId)")
    }

    static func activateProfile(_ profileId: Profile.ID) -> Self {
        Self("activateProfile_\(profileId)")
    }
}
