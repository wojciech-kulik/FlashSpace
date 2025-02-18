//
//  WorkspaceCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class WorkspaceCommands: CommandExecutor {
    var workspaceManager: WorkspaceManager { AppDependencies.shared.workspaceManager }
    var workspaceRepository: WorkspaceRepository { AppDependencies.shared.workspaceRepository }

    // swiftlint:disable:next cyclomatic_complexity
    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .activateWorkspace(.some(let name), _):
            let workspace = workspaceRepository.workspaces.first { $0.name == name }
            if let workspace {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        case .activateWorkspace(_, .some(let number)):
            let workspace = workspaceRepository.workspaces[safe: number - 1]
            if let workspace {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        case .nextWorkspace:
            workspaceManager.activateWorkspace(next: true)
            return CommandResponse(success: true)

        case .previousWorkspace:
            workspaceManager.activateWorkspace(next: false)
            return CommandResponse(success: true)

        case .recentWorkspace:
            workspaceManager.activateRecentWorkspace()
            return CommandResponse(success: true)

        case .createWorkspace(let request):
            let workspace = request.toWorkspace
            workspaceRepository.addWorkspace(workspace)
            if request.activate {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
            }
            NotificationCenter.default.post(name: .appsListChanged, object: nil)
            return CommandResponse(success: true)

        case .deleteWorkspace(let name):
            let workspace = workspaceRepository.workspaces.first { $0.name == name }
            if let workspace {
                workspaceRepository.deleteWorkspace(id: workspace.id)
                NotificationCenter.default.post(name: .appsListChanged, object: nil)
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        default:
            return nil
        }
    }
}
