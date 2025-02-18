//
//  ListDisplays.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ArgumentParser
import Foundation

struct ListDisplaysCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list-displays",
        abstract: "List displays"
    )

    func run() throws {
        for screen in NSScreen.screens {
            print(screen.localizedName)
        }
    }
}
