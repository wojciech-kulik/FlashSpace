//
//  ActivateCommand.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ActivateCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "activate",
        abstract: "Activate a workspace"
    )

    @Option(help: "The name of the workspace to activate")
    var workspace: String?

    @Flag(help: "Activate the next workspace")
    var nextWorkspace = false

    @Flag(name: .customLong("prev-workspace"), help: "Activate the previous workspace")
    var previousWorkspace = false

    func run() throws {
        if let workspace {
            SocketClient.shared.sendCommand(.activateWorkspace(name: workspace))
        } else if nextWorkspace {
            SocketClient.shared.sendCommand(.nextWorkspace)
        } else if previousWorkspace {
            SocketClient.shared.sendCommand(.previousWorkspace)
        } else {
            print(Self.helpMessage(for: ActivateCommand.self))
            Self.exit(withError: CommandError.other)
        }

        RunLoop.current.run(until: Date().addingTimeInterval(5.0))
        Self.exit(withError: CommandError.timeout)
    }
}
