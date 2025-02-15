//
//  Migrations.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Migrations {
    static var appsMigrated = false
    static var hotKeysMigrated = false

    static func migrateIfNeeded(
        settingsRepository: SettingsRepository,
        profilesRepository: ProfilesRepository
    ) {
        if Migrations.appsMigrated {
            print("Migrated apps")

            let workspacesJsonUrl = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent(".config/flashspace/workspaces.json")
            try? FileManager.default.moveItem(
                at: workspacesJsonUrl,
                to: workspacesJsonUrl.deletingLastPathComponent()
                    .appendingPathComponent("workspaces.json.bak")
            )

            settingsRepository.saveToDisk()
            profilesRepository.saveToDisk()
        } else if Migrations.hotKeysMigrated {
            print("Migrated hot keys")
            settingsRepository.saveToDisk()
            profilesRepository.saveToDisk()
        }

        Migrations.appsMigrated = false
        Migrations.hotKeysMigrated = false
    }
}
