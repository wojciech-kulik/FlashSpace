//
//  AppDependencies.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let displayManager: DisplayManager
    let workspaceRepository: WorkspaceRepository
    let workspaceManager: WorkspaceManager
    let workspaceHotKeys: WorkspaceHotKeys
    let workspaceScreenshotManager: WorkspaceScreenshotManager
    let workspaceTransitionManager: WorkspaceTransitionManager
    let pictureInPictureManager: PictureInPictureManager

    let floatingAppsHotKeys: FloatingAppsHotKeys

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let focusManager: FocusManager
    let focusedWindowTracker: FocusedWindowTracker

    let settingsRepository: SettingsRepository
    let generalSettings = GeneralSettings()
    let menuBarSettings = MenuBarSettings()
    let gesturesSettings = GesturesSettings()
    let focusManagerSettings = FocusManagerSettings()
    let workspaceSettings = WorkspaceSettings()
    let floatingAppsSettings = FloatingAppsSettings()
    let spaceControlSettings = SpaceControlSettings()
    let integrationsSettings = IntegrationsSettings()

    let profilesRepository: ProfilesRepository
    let autostartService = AutostartService()
    let cliServer = CLIServer()

    // swiftlint:disable:next function_body_length
    private init() {
        self.settingsRepository = SettingsRepository(
            generalSettings: generalSettings,
            menuBarSettings: menuBarSettings,
            gesturesSettings: gesturesSettings,
            focusManagerSettings: focusManagerSettings,
            workspaceSettings: workspaceSettings,
            floatingAppsSettings: floatingAppsSettings,
            spaceControlSettings: spaceControlSettings,
            integrationsSettings: integrationsSettings
        )
        self.displayManager = DisplayManager(settingsRepository: settingsRepository)
        self.workspaceTransitionManager = WorkspaceTransitionManager(
            workspaceSettings: workspaceSettings
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
            profilesRepository: profilesRepository,
            pictureInPictureManager: pictureInPictureManager,
            workspaceTransitionManager: workspaceTransitionManager,
            displayManager: displayManager
        )
        self.workspaceHotKeys = WorkspaceHotKeys(
            workspaceManager: workspaceManager,
            workspaceRepository: workspaceRepository,
            settingsRepository: settingsRepository
        )
        self.floatingAppsHotKeys = FloatingAppsHotKeys(
            workspaceManager: workspaceManager,
            settingsRepository: settingsRepository
        )
        self.focusManager = FocusManager(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            focusManagerSettings: focusManagerSettings,
            floatingAppsSettings: floatingAppsSettings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            workspaceHotKeys: workspaceHotKeys,
            floatingAppsHotKeys: floatingAppsHotKeys,
            focusManager: focusManager,
            settingsRepository: settingsRepository
        )
        self.focusedWindowTracker = FocusedWindowTracker(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            settingsRepository: settingsRepository,
            pictureInPictureManager: pictureInPictureManager
        )
        self.workspaceScreenshotManager = WorkspaceScreenshotManager(
            spaceControlSettings: spaceControlSettings,
            workspaceManager: workspaceManager
        )

        Migrations.migrateIfNeeded(
            settingsRepository: settingsRepository,
            profilesRepository: profilesRepository
        )

        focusedWindowTracker.startTracking()
    }
}
