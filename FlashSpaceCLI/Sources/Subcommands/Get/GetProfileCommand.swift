//
//  GetProfileCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct GetProfileCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "get-profile",
        abstract: "Get active profile"
    )

    func run() throws {
        sendCommand(.getProfile)
        runWithTimeout()
    }
}
