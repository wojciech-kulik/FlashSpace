//
//  DeleteProfileCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct DeleteProfileCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "delete-profile",
        abstract: "Delete a profile"
    )

    @Argument(help: "The name of the profile to delete.")
    var name: String

    func run() throws {
        sendCommand(.deleteProfile(name: name))
        runWithTimeout()
    }
}
