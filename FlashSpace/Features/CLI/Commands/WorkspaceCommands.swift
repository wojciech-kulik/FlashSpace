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

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .activateWorkspace(.some(let name), _, let clean):
            let workspace = workspaceRepository.workspaces.first { $0.name == name }
            if let workspace {
                if workspace.isDynamic, workspace.displays.isEmpty {
                    return CommandResponse(success: false, error: "\(workspace.name) - No Running Apps To Show")
                }
                workspaceManager.activateWorkspace(workspace, setFocus: true)
                if clean { workspaceManager.hideUnassignedApps() }
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        case .activateWorkspace(_, .some(let number), let clean):
            let workspace = workspaceRepository.workspaces[safe: number - 1]
            if let workspace {
                if workspace.isDynamic, workspace.displays.isEmpty {
                    return CommandResponse(success: false, error: "\(workspace.name) - No Running Apps To Show")
                }
                workspaceManager.activateWorkspace(workspace, setFocus: true)
                if clean { workspaceManager.hideUnassignedApps() }
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Workspace not found")
            }

        case .updateWorkspace(let request):
            return updateWorkspace(request)

        case .nextWorkspace(let skipEmpty, let clean, let loop):
            workspaceManager.activateWorkspace(next: true, skipEmpty: skipEmpty, loop: loop)
            if clean { workspaceManager.hideUnassignedApps() }
            return CommandResponse(success: true)

        case .previousWorkspace(let skipEmpty, let clean, let loop):
            workspaceManager.activateWorkspace(next: false, skipEmpty: skipEmpty, loop: loop)
            if clean { workspaceManager.hideUnassignedApps() }
            return CommandResponse(success: true)

        case .recentWorkspace(let clean):
            workspaceManager.activateRecentWorkspace()
            if clean { workspaceManager.hideUnassignedApps() }
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

    private func updateWorkspace(_ request: UpdateWorkspaceRequest) -> CommandResponse {
        var workspace: Workspace?
        if let workspaceName = request.name {
            workspace = workspaceRepository.workspaces.first { $0.name == workspaceName }
        } else if let workspaceId = workspaceManager.activeWorkspaceDetails?.id {
            workspace = workspaceRepository.workspaces.first { $0.id == workspaceId }
        } else {
            return CommandResponse(success: false, error: "Workspace not found")
        }

        guard var workspace else {
            return CommandResponse(success: false, error: "Workspace not found")
        }

        if let display = request.display {
            switch display {
            case .active:
                if let display = NSWorkspace.shared.frontmostApplication?.display {
                    workspace.display = display
                } else {
                    return CommandResponse(success: false, error: "No active display found")
                }
            case .name(let name):
                workspace.display = name
            }
        }

        workspaceRepository.updateWorkspace(workspace)
        NotificationCenter.default.post(name: .appsListChanged, object: nil)

        return CommandResponse(success: true)
    }
}
