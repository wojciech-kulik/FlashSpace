//
//  WorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct WorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "workspace",
        abstract: "Activate a workspace"
    )

    @Option(help: .init("The name of the workspace"))
    var name: String?

    @Option(help: .init(
        "The number of the workspace to activate. Starting from 1.",
        valueName: "number"
    ))
    var number: Int?

    @Flag(help: "Activate the next workspace")
    var next = false

    @Flag(help: "Activate the previous workspace")
    var prev = false

    func run() throws {
        if let name {
            SocketClient.shared.sendCommand(.activateWorkspace(name: name))
        } else if let number {
            SocketClient.shared.sendCommand(.activateWorkspaceNumber(number: number))
        } else if next {
            SocketClient.shared.sendCommand(.nextWorkspace)
        } else if prev {
            SocketClient.shared.sendCommand(.previousWorkspace)
        } else {
            print(Self.helpMessage(for: WorkspaceCommand.self))
            Self.exit(withError: CommandError.other)
        }

        RunLoop.current.run(until: Date().addingTimeInterval(5.0))
        Self.exit(withError: CommandError.timeout)
    }
}
