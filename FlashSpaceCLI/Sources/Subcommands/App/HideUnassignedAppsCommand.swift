//
//  HideUnassignedAppsCommand.swift
//
//  Created by Wojciech Kulik on 07/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct HideUnassignedAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "hide-unassigned-apps",
        abstract: "Hide all unassigned apps"
    )

    func run() throws {
        sendCommand(.hideUnassignedApps)
        runWithTimeout()
    }
}
