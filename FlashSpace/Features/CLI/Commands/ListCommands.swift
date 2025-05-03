//
//  ListCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class ListCommands: CommandExecutor {
    var workspaceRepository: WorkspaceRepository { AppDependencies.shared.workspaceRepository }
    var profilesRepository: ProfilesRepository { AppDependencies.shared.profilesRepository }
    var settingsRepository: SettingsRepository { AppDependencies.shared.settingsRepository }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .listWorkspaces(let withDisplay, let profileName):
            let profile = profileName != nil
                ? profilesRepository.profiles.first { $0.name == profileName }
                : profilesRepository.selectedProfile

            if let profile {
                let result = withDisplay
                    ? profile.workspaces.map { "\($0.name),\($0.displayWithFallback)" }.joined(separator: "\n")
                    : profile.workspaces.map(\.name).joined(separator: "\n")
                return CommandResponse(success: true, message: result)
            } else {
                return CommandResponse(success: false, error: "Profile not found")
            }

        case .listProfiles:
            let result = profilesRepository.profiles.map(\.name).joined(separator: "\n")
            return CommandResponse(success: true, message: result)

        case .listApps(let workspace, let profileName, let withBundleId, let withIcon, let onlyRunning):
            let profile = profileName != nil
                ? profilesRepository.profiles.first { $0.name == profileName }
                : profilesRepository.selectedProfile

            guard let profile else {
                return CommandResponse(success: false, error: "Profile not found")
            }

            guard let workspace = profile.workspaces.first(where: { $0.name == workspace }) else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

            let runningApps = Set(NSWorkspace.shared.runningApplications.map(\.bundleIdentifier))

            let result = workspace.apps
                .filter { !onlyRunning || runningApps.contains($0.bundleIdentifier) }
                .map { app in
                    [
                        app.name,
                        withBundleId ? app.bundleIdentifier : nil,
                        withIcon ? app.iconPath ?? "" : nil
                    ].compactMap { $0 }.joined(separator: ",")
                }
                .joined(separator: "\n")

            return CommandResponse(success: true, message: result)

        case .listFloatingApps(let withBundleId):
            let floatingApps = settingsRepository.floatingAppsSettings.floatingApps
                .map { app in
                    [
                        app.name,
                        withBundleId ? app.bundleIdentifier : nil
                    ].compactMap { $0 }.joined(separator: ",")
                }
                .joined(separator: "\n")

            return CommandResponse(success: true, message: floatingApps)

        default:
            return nil
        }
    }
}
