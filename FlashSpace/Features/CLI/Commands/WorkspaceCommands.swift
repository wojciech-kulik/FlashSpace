//
//  WorkspaceCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class WorkspaceCommands: CommandExecutor {
    var workspaceManager: WorkspaceManager { AppDependencies.shared.workspaceManager }
    var workspaceRepository: WorkspaceRepository { AppDependencies.shared.workspaceRepository }
    var workspaceHotKeys: WorkspaceHotKeys { AppDependencies.shared.workspaceHotKeys }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .activateWorkspace(let name):
            let workspace = workspaceRepository.workspaces.first { $0.name == name }
            if let workspace {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        case .nextWorkspace:
            workspaceHotKeys.getCycleWorkspacesHotKey(next: true)?.1()
            return CommandResponse(success: true)

        case .previousWorkspace:
            workspaceHotKeys.getCycleWorkspacesHotKey(next: false)?.1()
            return CommandResponse(success: true)

        default:
            return nil
        }
    }
}
