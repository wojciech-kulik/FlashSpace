//
//  ListAppsCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ListAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-apps",
        abstract: "List workspace apps"
    )

    @Argument(help: "Workspace name")
    var workspace: String

    @Option(help: "Profile name")
    var profile: String?

    @Flag(help: "Include bundle id")
    var withBundleId = false

    @Flag(help: "Include icon")
    var withIcon = false

    @Flag(help: "Only running apps")
    var onlyRunning = false

    func run() throws {
        sendCommand(.listApps(
            workspace: workspace,
            profile: profile,
            withBundleId: withBundleId,
            withIcon: withIcon,
            onlyRunning: onlyRunning
        ))
        runWithTimeout()
    }
}
