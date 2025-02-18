//
//  AppDependencies.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let workspaceRepository: WorkspaceRepository
    let workspaceManager: WorkspaceManager
    let workspaceHotKeys: WorkspaceHotKeys
    let workspaceScreenshotManager = WorkspaceScreenshotManager()
    let pictureInPictureManager: PictureInPictureManager

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let focusManager: FocusManager
    let focusedWindowTracker: FocusedWindowTracker

    let settingsRepository: SettingsRepository
    let generalSettings = GeneralSettings()
    let menuBarSettings = MenuBarSettings()
    let focusManagerSettings = FocusManagerSettings()
    let workspaceSettings = WorkspaceSettings()
    let floatingAppsSettings = FloatingAppsSettings()
    let spaceControlSettings = SpaceControlSettings()
    let integrationsSettings = IntegrationsSettings()

    let profilesRepository: ProfilesRepository
    let autostartService = AutostartService()
    let cliServer = CLIServer()

    private init() {
        self.settingsRepository = SettingsRepository(
            generalSettings: generalSettings,
            menuBarSettings: menuBarSettings,
            focusManagerSettings: focusManagerSettings,
            workspaceSettings: workspaceSettings,
            floatingAppsSettings: floatingAppsSettings,
            spaceControlSettings: spaceControlSettings,
            integrationsSettings: integrationsSettings
        )
        self.pictureInPictureManager = PictureInPictureManager(
            settingsRepository: settingsRepository
        )
        self.profilesRepository = ProfilesRepository()
        self.workspaceRepository = WorkspaceRepository(
            profilesRepository: profilesRepository
        )
        self.workspaceManager = WorkspaceManager(
            workspaceRepository: workspaceRepository,
            settingsRepository: settingsRepository,
            pictureInPictureManager: pictureInPictureManager
        )
        self.workspaceHotKeys = WorkspaceHotKeys(
            workspaceManager: workspaceManager,
            workspaceRepository: workspaceRepository,
            settingsRepository: settingsRepository
        )
        self.focusManager = FocusManager(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            focusManagerSettings: focusManagerSettings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            workspaceHotKeys: workspaceHotKeys,
            focusManager: focusManager,
            settingsRepository: settingsRepository
        )
        self.focusedWindowTracker = FocusedWindowTracker(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            settingsRepository: settingsRepository,
            pictureInPictureManager: pictureInPictureManager
        )

        Migrations.migrateIfNeeded(
            settingsRepository: settingsRepository,
            profilesRepository: profilesRepository
        )

        focusedWindowTracker.startTracking()
    }
}
