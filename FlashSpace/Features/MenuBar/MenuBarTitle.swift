//
//  MenuBarTitle.swift
//
//  Created by Wojciech Kulik on 31/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum MenuBarTitle {
    static let settings = AppDependencies.shared.menuBarSettings
    static let workspaceManager = AppDependencies.shared.workspaceManager
    static let profilesRepository = AppDependencies.shared.profilesRepository

    @MainActor
    static func get() async -> String? {
        let template = settings.menuBarTitleTemplate.trimmingCharacters(in: .whitespaces)
        let useScript = settings.menuBarTitleUseScript
        let scriptPath = settings.menuBarTitleScriptPath.trimmingCharacters(in: .whitespaces)

        guard settings.showMenuBarTitle, !template.isEmpty || useScript else { return nil }
        guard let activeWorkspace = workspaceManager.activeWorkspaceDetails else { return nil }

        if useScript {
            guard scriptPath.isNotEmpty, FileManager.default.fileExists(atPath: scriptPath) else { return nil }
            return await Terminal.runScriptWithOutput(scriptPath)
        }

        return template
            .replacingOccurrences(of: "$WORKSPACE_NUMBER", with: activeWorkspace.number ?? "")
            .replacingOccurrences(of: "$WORKSPACE", with: activeWorkspace.name)
            .replacingOccurrences(of: "$DISPLAY", with: getDisplayName())
            .replacingOccurrences(of: "$PROFILE", with: profilesRepository.selectedProfile.name)
    }

    private static func getDisplayName() -> String {
        let aliases = settings.menuBarDisplayAliases
            .split(separator: ";")
            .map { $0.split(separator: "=") }
            .reduce(into: [String: String]()) { result, pair in
                guard pair.count == 2 else { return }

                result[String(pair[0]).lowercased()] = String(pair[1])
            }

        let display = workspaceManager.activeWorkspaceDetails?.display ?? ""

        return aliases[display.lowercased()] ?? display
    }
}
