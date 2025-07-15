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

    @Flag(help: "Activate the most recently used workspace")
    var recent = false

    @Flag(help: "Skip empty workspaces (works only with --next or --prev)")
    var skipEmpty = false

    @Flag(help: "Loop back to the first workspace when reaching the last one and vice versa (works only with --next or --prev)")
    var loop = false

    @Flag(help: "Hide all apps that are not assigned to the selected workspace")
    var clean = false

    func run() throws {
        if let name {
            sendCommand(.activateWorkspace(name: name, number: nil, clean: clean))
        } else if let number {
            sendCommand(.activateWorkspace(name: nil, number: number, clean: clean))
        } else if next {
            sendCommand(.nextWorkspace(skipEmpty: skipEmpty, clean: clean, loop: loop))
        } else if prev {
            sendCommand(.previousWorkspace(skipEmpty: skipEmpty, clean: clean, loop: loop))
        } else if recent {
            sendCommand(.recentWorkspace(clean: clean))
        } else {
            fallbackToHelp()
        }

        runWithTimeout()
    }
}
