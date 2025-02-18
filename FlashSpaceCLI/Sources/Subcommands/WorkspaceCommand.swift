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
            sendCommand(.activateWorkspace(name: name, number: nil))
        } else if let number {
            sendCommand(.activateWorkspace(name: nil, number: number))
        } else if next {
            sendCommand(.nextWorkspace)
        } else if prev {
            sendCommand(.previousWorkspace)
        } else {
            fallbackToHelp()
        }

        runWithTimeout()
    }
}
