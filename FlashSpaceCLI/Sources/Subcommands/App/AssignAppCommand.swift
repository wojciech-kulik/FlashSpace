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
        "The name of the app or bundle id. If not provided, the active app will be assigned. Default: active app.",
        valueName: "name|bundle id"
    ))
    var name: String?

    @Option(
        name: .customLong("workspace"),
        help: .init("The name of the workspace to assign the app to. Default: active workspace.", valueName: "name")
    )
    var workspace: String?

    @Option(help: .init(
        "Activate workspace. Default: from app settings.",
        valueName: "true|false"
    ))
    var activate: Bool?

    @Flag(help: "Show toast notification")
    var showNotification = false

    func run() throws {
        sendCommand(
            .assignApp(
                app: name,
                workspaceName: workspace,
                activate: activate,
                showNotification: showNotification
            )
        )
        runWithTimeout()
    }
}
