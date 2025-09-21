//
//  ProfileCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct ProfileCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "profile",
        abstract: "Activate a profile"
    )

    @Argument(help: "Profile name.")
    var name: String?

    @Flag(help: "Activate next profile")
    var next = false

    @Flag(help: "Activate previous profile")
    var prev = false

    func run() throws {
        if let name {
            sendCommand(.activateProfile(name: name))
        } else if next {
            sendCommand(.nextProfile)
        } else if prev {
            sendCommand(.previousProfile)
        }
        runWithTimeout()
    }

    func validate() throws {
        if !next, !prev, name == nil {
            throw CommandError.operationFailed("You must provide a profile name or use --next or --prev")
        }

        if next || prev, name != nil {
            throw CommandError.operationFailed("You cannot provide a profile name and use --next or --prev")
        }
    }
}
