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
    let workspaceManager = WorkspaceManager()

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager = HotKeysManager(hotKeysMonitor: GlobalShortcutMonitor.shared)

    let autostartService = AutostartService()

    private init() {}
}
