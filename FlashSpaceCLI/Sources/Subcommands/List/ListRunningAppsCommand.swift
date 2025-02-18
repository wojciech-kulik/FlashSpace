//
//  ListRunningAppsCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct ListRunningAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-running-apps",
        abstract: "List running apps"
    )

    func run() throws {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap(\.localizedName)

        let result = Set(apps).sorted().joined(separator: "\n")
        print(result)
    }
}
