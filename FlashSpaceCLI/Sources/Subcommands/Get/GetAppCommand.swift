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

    @Flag(help: "Include windows count")
    var withWindowsCount = false

    func run() throws {
        sendCommand(.getApp(withWindowsCount: withWindowsCount))
        runWithTimeout()
    }
}
