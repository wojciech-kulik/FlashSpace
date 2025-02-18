//
//  GetDisplayCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct GetDisplayCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "get-display",
        abstract: "Get active display"
    )

    func run() throws {
        sendCommand(.getDisplay)
        runWithTimeout()
    }
}
