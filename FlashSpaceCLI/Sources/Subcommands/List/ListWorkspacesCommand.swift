//
//  ListWorkspacesCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ListWorkspacesCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-workspaces",
        abstract: "List workspaces"
    )

    @Flag(help: "Include assigned display name")
    var withDisplay = false

    @Option(help: "Profile name")
    var profile: String?

    func run() throws {
        sendCommand(.listWorkspaces(withDisplay: withDisplay, profile: profile))
        runWithTimeout()
    }
}
