//
//  AssignVisibleAppsCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct AssignVisibleAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "assign-visible-apps",
        abstract: "Assign visible apps to a workspace"
    )

    @Option(
        name: .customLong("workspace"),
        help: .init("The name of the workspace to assign apps to. Default: active workspace.", valueName: "name")
    )
    var workspace: String?

    @Flag(help: "Show toast notification")
    var showNotification = false

    func run() throws {
        sendCommand(
            .assignVisibleApps(workspaceName: workspace, showNotification: showNotification)
        )
        runWithTimeout()
    }
}
