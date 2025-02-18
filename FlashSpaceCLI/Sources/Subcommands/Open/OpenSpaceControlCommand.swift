//
//  OpenSpaceControlCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct OpenSpaceControlCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "open-space-control",
        abstract: "Open Space Control"
    )

    func run() throws {
        sendCommand(.openSpaceControl)
        runWithTimeout()
    }
}
