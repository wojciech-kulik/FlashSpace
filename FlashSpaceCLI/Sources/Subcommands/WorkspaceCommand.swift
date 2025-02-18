//
//  WorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct WorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "workspace",
        abstract: "Manage workspaces"
    )

    @Option(
        name: .customLong("name"),
        help: .init("Applicable for --assign-app", valueName: "workspace name")
    )
    var workspace: String?

    @Option(help: .init(
        "Activate the workspace after assigning the app. Default: app config.",
        valueName: "true|false"
    ))
    var activate: Bool?

    @Option(help: .init(
        "The name of the app or bundle id to assign to a workspace",
        valueName: "name|bundle id"
    ))
    var assignApp: String?

    @Option(help: .init(
        "The name of the app or bundle id to unassign from all workspaces",
        valueName: "name|bundle id"
    ))
    var unassignApp: String?

    func run() throws {
        if let assignApp {
            SocketClient.shared.sendCommand(.assignApp(app: assignApp, workspaceName: workspace, activate: activate))
        } else if let unassignApp {
            SocketClient.shared.sendCommand(.unassignApp(app: unassignApp))
        } else {
            print(Self.helpMessage(for: WorkspaceCommand.self))
            Self.exit(withError: CommandError.other)
        }

        RunLoop.current.run(until: Date().addingTimeInterval(5.0))
        Self.exit(withError: CommandError.timeout)
    }
}
