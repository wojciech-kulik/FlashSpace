//
//  CreateWorkspaceCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

struct CreateWorkspaceRequest: Codable {
    let name: String
    let display: String?
    let icon: String?
    let activateKey: String?
    let assignKey: String?
    let openApps: Bool
    let activate: Bool
}

struct CreateWorkspaceCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "create-workspace",
        abstract: "Create a workspace"
    )

    @Argument(help: "The name of the workspace to create.")
    var name: String

    @Option(help: .init("The name of the display", valueName: "name"))
    var display: String?

    @Option(help: "The name of the icon to use for the workspace. Must match SF Symbols.")
    var icon: String?

    @Option(help: "The hotkey to activate the workspace")
    var activateKey: String?

    @Option(help: "The hotkey to assign the app")
    var assignKey: String?

    @Flag(help: "Open apps on workspace activation")
    var openApps = false

    @Flag(help: "Activate the new workspace")
    var activate = false

    func run() throws {
        let request = CreateWorkspaceRequest(
            name: name,
            display: display,
            icon: icon,
            activateKey: activateKey,
            assignKey: assignKey,
            openApps: openApps,
            activate: activate
        )
        sendCommand(.createWorkspace(request))
        runWithTimeout()
    }
}
