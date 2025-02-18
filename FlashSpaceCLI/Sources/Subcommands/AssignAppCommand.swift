//
//  AssignAppCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct AssignAppCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "assign-app",
        abstract: "Assign an app to a workspace"
    )

    @Option(help: .init(
        "The name of the app or bundle id. If not provided, the active app will be assigned.",
        valueName: "name|bundle id"
    ))
    var name: String?

    @Option(
        name: .customLong("workspace"),
        help: .init("The name of the workspace to assign the app to", valueName: "name")
    )
    var workspace: String?

    @Option(help: .init(
        "Activate the workspace. Default: app config.",
        valueName: "true|false"
    ))
    var activate: Bool?

    func run() throws {
        sendCommand(.assignApp(app: name, workspaceName: workspace, activate: activate))
        runWithTimeout()
    }
}
