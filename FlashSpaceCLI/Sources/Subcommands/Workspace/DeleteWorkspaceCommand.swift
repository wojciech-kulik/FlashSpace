//
//  DeleteWorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct DeleteWorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "delete-workspace",
        abstract: "Delete a workspace"
    )

    @Argument(help: "The name of the workspace to delete.")
    var name: String

    func run() throws {
        sendCommand(.deleteWorkspace(name: name))
        runWithTimeout()
    }
}
