//
//  ListFloatingAppsCommand.swift
//
//  Created by Wojciech Kulik on 03/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ListFloatingAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-floating-apps",
        abstract: "List floating apps"
    )

    @Flag(help: "Include bundle id")
    var withBundleId = false

    func run() throws {
        sendCommand(.listFloatingApps(withBundleId: withBundleId))
        runWithTimeout()
    }
}
