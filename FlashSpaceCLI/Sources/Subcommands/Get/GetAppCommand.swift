//
//  GetAppCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct GetAppCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "get-app",
        abstract: "Get active app"
    )

    func run() throws {
        sendCommand(.getApp)
        runWithTimeout()
    }
}
