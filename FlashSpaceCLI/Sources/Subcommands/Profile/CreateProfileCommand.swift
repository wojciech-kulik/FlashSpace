//
//  CreateProfileCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct CreateProfileCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "create-profile",
        abstract: "Create a profile"
    )

    @Argument(help: "The name of the profile to create.")
    var name: String

    @Flag(help: "Copy current profile")
    var copy = false

    @Flag(help: "Activate new profile")
    var activate = false

    func run() throws {
        sendCommand(.createProfile(name: name, copy: copy, activate: activate))
        runWithTimeout()
    }
}
