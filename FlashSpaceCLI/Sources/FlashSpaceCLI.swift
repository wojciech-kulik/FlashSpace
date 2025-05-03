//
//  FlashSpaceCLI.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

@main
struct FlashSpaceCLI: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "flashspace",
        abstract: "FlashSpace CLI",
        version: "1.0.0",
        groupedSubcommands: [
            .init(
                name: "Profile",
                subcommands: [
                    CreateProfileCommand.self,
                    DeleteProfileCommand.self,
                    ProfileCommand.self
                ]
            ),
            .init(
                name: "Workspace",
                subcommands: [
                    CreateWorkspaceCommand.self,
                    DeleteWorkspaceCommand.self,
                    UpdateWorkspaceCommand.self,
                    WorkspaceCommand.self
                ]
            ),
            .init(
                name: "App",
                subcommands: [
                    AssignAppCommand.self,
                    UnassignAppCommand.self,
                    FocusCommand.self,
                    FloatingAppsCommand.self
                ]
            ),
            .init(
                name: "List",
                subcommands: [
                    ListProfilesCommand.self,
                    ListWorkspacesCommand.self,
                    ListAppsCommand.self,
                    ListFloatingAppsCommand.self,
                    ListRunningAppsCommand.self,
                    ListDisplaysCommand.self
                ]
            ),
            .init(
                name: "Get",
                subcommands: [
                    GetProfileCommand.self,
                    GetWorkspaceCommand.self,
                    GetAppCommand.self,
                    GetDisplayCommand.self
                ]
            ),
            .init(
                name: "Open",
                subcommands: [
                    OpenAppCommand.self,
                    OpenSpaceControlCommand.self
                ]
            )
        ]
    )
}
