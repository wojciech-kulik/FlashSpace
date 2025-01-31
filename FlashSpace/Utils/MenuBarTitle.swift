//
//  MenuBarTitle.swift
//
//  Created by Wojciech Kulik on 31/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

enum MenuBarTitle {
    static let settings = AppDependencies.shared.settingsRepository
    static let workspaceManager = AppDependencies.shared.workspaceManager
    static let profilesRepository = AppDependencies.shared.profilesRepository

    static func get() -> String? {
        let template = settings.menuBarTitleTemplate.trimmingCharacters(in: .whitespaces)

        guard settings.showMenuBarTitle, !template.isEmpty else { return nil }
        guard let activeWorkspace = workspaceManager.activeWorkspaceDetails else { return nil }

        return template
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: activeWorkspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: activeWorkspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: activeWorkspace.display)
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
    }
}
