//
//  OpenAppCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct OpenAppCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open FlashSpace"
    )

    func run() throws {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "pl.wojciechkulik.FlashSpace.dev")
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "pl.wojciechkulik.FlashSpace")

        if let url {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                if let error {
                    Self.exit(withError: CommandError.operationFailed("Failed to open FlashSpace: \(error.localizedDescription)"))
                } else {
                    Self.exit()
                }
            }
            runWithTimeout()
        } else {
            throw CommandError.operationFailed("FlashSpace is not installed.")
        }
    }
}
