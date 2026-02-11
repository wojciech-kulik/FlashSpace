//
//  GetCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class GetCommands: CommandExecutor {
    var workspaceManager: WorkspaceManager { AppDependencies.shared.workspaceManager }
    var profilesRepository: ProfilesRepository { AppDependencies.shared.profilesRepository }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .getProfile:
            let result = profilesRepository.selectedProfile.name
            return CommandResponse(success: true, message: result)

        case .getWorkspace(let display):
            let workspace = workspaceManager.activeWorkspace[display ?? .current]
            if let workspace {
                let result = workspace.name
                return CommandResponse(success: true, message: result)
            } else {
                return CommandResponse(success: false, error: "No active workspace")
            }

        case .getApp(let withWindowsCount):
            if let app = NSWorkspace.shared.frontmostApplication, let appName = app.localizedName {
                if withWindowsCount {
                    return CommandResponse(success: true, message: "\(appName)\n\(app.allWindows.count)")
                } else {
                    return CommandResponse(success: true, message: appName)
                }
            } else {
                return CommandResponse(success: false, error: "No active app")
            }

        case .getDisplay:
            if let display = DisplayName.currentOptional {
                return CommandResponse(success: true, message: display)
            } else {
                return CommandResponse(success: false, error: "No display found")
            }

        default:
            return nil
        }
    }
}
