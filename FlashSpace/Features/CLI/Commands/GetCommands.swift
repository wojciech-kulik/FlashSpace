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
            let workspace = workspaceManager.activeWorkspace[display ?? NSScreen.main?.localizedName ?? ""]
            if let workspace {
                let result = workspace.name
                return CommandResponse(success: true, message: result)
            } else {
                return CommandResponse(success: false, error: "No active workspace")
            }

        case .getApp:
            if let app = NSWorkspace.shared.frontmostApplication?.localizedName {
                return CommandResponse(success: true, message: app)
            } else {
                return CommandResponse(success: false, error: "No active app")
            }

        case .getDisplay:
            if let display = NSScreen.main?.localizedName {
                return CommandResponse(success: true, message: display)
            } else {
                return CommandResponse(success: false, error: "No display found")
            }

        default:
            return nil
        }
    }
}
