//
//  FocusCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct FocusCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "focus",
        abstract: "Focus window"
    )

    @Option(
        name: .customLong("direction"),
        help: .init("Focus a window in a specific direction", valueName: "up|down|left|right")
    )
    var focusDirection: FocusDirection?

    @Flag(help: "Focus the next workspace app")
    var nextApp = false

    @Flag(help: "Focus the previous workspace app")
    var prevApp = false

    @Flag(help: "Focus the next workspace window")
    var nextWindow = false

    @Flag(help: "Focus the previous workspace window")
    var prevWindow = false

    func run() throws {
        if let focusDirection {
            sendCommand(.focusWindow(direction: focusDirection))
        } else if nextApp {
            sendCommand(.focusNextApp)
        } else if prevApp {
            sendCommand(.focusPreviousApp)
        } else if nextWindow {
            sendCommand(.focusNextWindow)
        } else if prevWindow {
            sendCommand(.focusPreviousWindow)
        } else {
            fallbackToHelp()
        }

        runWithTimeout()
    }
}
