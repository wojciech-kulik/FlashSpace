//
//  UpdateWorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 02/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct UpdateWorkspaceRequest: Codable {
    enum Display: Codable {
        case active
        case name(String)
    }

    let name: String?
    let display: Display?
}

struct UpdateWorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "update-workspace",
        abstract: "Update a workspace"
    )

    @Option(help: "The name of the workspace to update.")
    var workspace: String?

    @Flag(help: "Update active workspace.")
    var activeWorkspace = false

    @Option(help: "The name of the display to be assigned.")
    var display: String?

    @Flag(help: "Assign active display.")
    var activeDisplay = false

    func run() throws {
        if let display {
            sendCommand(.updateWorkspace(.init(name: workspace, display: .name(display))))
        } else if activeDisplay {
            sendCommand(.updateWorkspace(.init(name: workspace, display: .active)))
        } else {
            throw CommandError.operationFailed("Invalid command")
        }

        runWithTimeout()
    }

    func validate() throws {
        if workspace != nil, activeWorkspace {
            throw CommandError.operationFailed("You cannot provide both a workspace name and use the --active-workspace flag")
        }

        if display != nil, activeDisplay {
            throw CommandError.operationFailed("You cannot provide both a display name and use the --active-display flag")
        }

        if workspace == nil, !activeWorkspace {
            throw CommandError.operationFailed("You must provide either a workspace name or use the --active-workspace flag")
        }

        if display == nil, !activeDisplay {
            throw CommandError.operationFailed("You must provide either a display name or use the --active-display flag")
        }

        if let display, !NSScreen.screens.contains(where: { $0.localizedName == display }) {
            throw CommandError.operationFailed("Display \"\(display)\" not found")
        }
    }
}
