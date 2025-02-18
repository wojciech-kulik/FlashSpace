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
    var name: String

    func run() throws {
        sendCommand(.activateProfile(name: name))
        runWithTimeout()
    }
}
