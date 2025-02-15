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

    let autostartService = AutostartService()
    let focusedWindowTracker: FocusedWindowTracker
    let focusManager: FocusManager

    let settingsRepository = SettingsRepository()
    let profilesRepository: ProfilesRepository

    private init() {
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
            settingsRepository: settingsRepository
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
