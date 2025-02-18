//
//  UnassignAppCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct UnassignAppCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "unassign-app",
        abstract: "Unassign an app from all workspaces"
    )
    @Option(help: .init(
        "The name of the app or bundle id. If not provided, the active app will be unassigned. Default: active app.",
        valueName: "name|bundle id"
    ))
    var name: String?

    @Flag(help: "Show toast notification")
    var showNotification = false

    func run() throws {
        sendCommand(.unassignApp(app: name, showNotification: showNotification))
        runWithTimeout()
    }
}
