//
//  AppDependencies.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let workspaceRepository = WorkspaceRepository()
    let workspaceManager: WorkspaceManager

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let autostartService = AutostartService()
    let focusedWindowTracker: FocusedWindowTracker
    let focusManager: FocusManager

    let settingsRepository = SettingsRepository()

    private init() {
        self.workspaceManager = WorkspaceManager(
            workspaceRepository: workspaceRepository
        )
        self.focusManager = FocusManager(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            settingsRepository: settingsRepository
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            workspaceManager: workspaceManager,
            focusManager: focusManager
        )
        self.focusedWindowTracker = FocusedWindowTracker(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager
        )

        focusedWindowTracker.startTracking()
    }
}
