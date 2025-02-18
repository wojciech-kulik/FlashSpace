//
//  GetWorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct GetWorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "get-workspace",
        abstract: "Get active workspace"
    )

    @Option(help: "Display name")
    var display: String?

    func run() throws {
        sendCommand(.getWorkspace(display: display))
        runWithTimeout()
    }
}
