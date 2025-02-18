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
        "The name of the app or bundle id. If not provided, the active app will be unassigned.",
        valueName: "name|bundle id"
    ))
    var name: String?

    func run() throws {
        SocketClient.shared.sendCommand(.unassignApp(app: name))

        RunLoop.current.run(until: Date().addingTimeInterval(5.0))
        Self.exit(withError: CommandError.timeout)
    }
}
