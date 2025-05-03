//
//  FloatingAppsCommand.swift
//
//  Created by Wojciech Kulik on 03/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct FloatingAppsCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "floating-apps",
        abstract: "Manage floating apps"
    )

    enum Action: String, CaseIterable, ExpressibleByArgument {
        case float
        case unfloat
        case toggle
    }

    @Argument(help: "The action to perform")
    var action: Action

    @Option(help: .init(
        "The name of the app or bundle id. If not provided, the active app will be used. Default: active app.",
        valueName: "name|bundle id"
    ))
    var name: String?

    @Flag(help: "Show toast notification")
    var showNotification = false

    func run() throws {
        switch action {
        case .float:
            sendCommand(.floatApp(app: name, showNotification: showNotification))
        case .unfloat:
            sendCommand(.unfloatApp(app: name, showNotification: showNotification))
        case .toggle:
            sendCommand(.toggleFloatApp(app: name, showNotification: showNotification))
        }

        runWithTimeout()
    }
}
