//
//  ListProfilesCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ListProfilesCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-profiles",
        abstract: "List profiles"
    )

    func run() throws {
        sendCommand(.listProfiles)
        runWithTimeout()
    }
}
