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

    @Flag(help: "Include bundle id")
    var withBundleId = false

    func run() throws {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }

        let result = Set(apps)
            .filter { $0.localizedName != nil }
            .map { (bundleId: $0.bundleIdentifier ?? "-", name: $0.localizedName ?? "-") }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
            .map { app in
                if withBundleId {
                    return [app.name, app.bundleId].joined(separator: ",")
                } else {
                    return app.name
                }
            }
            .joined(separator: "\n")
        print(result)
    }
}
