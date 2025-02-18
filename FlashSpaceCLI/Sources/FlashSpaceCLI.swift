//
//  FlashSpaceCLI.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

@main
struct FlashSpaceCLI: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "flashspace",
        abstract: "FlashSpace CLI",
        version: "1.0.0",
        subcommands: [
            ActivateCommand.self,
            FocusCommand.self,
            WorkspaceCommand.self
        ]
    )
}
