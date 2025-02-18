//
//  CommandRequest.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

enum CommandRequest: Codable {
    case activateWorkspace(name: String)
    case nextWorkspace
    case previousWorkspace

    case assignApp(app: String?, workspaceName: String?, activate: Bool?)
    case unassignApp(app: String?)

    case focusWindow(direction: FocusDirection)
    case focusNextWindow
    case focusPreviousWindow
    case focusNextApp
    case focusPreviousApp

    case changeProfile(name: String)
}

enum FocusDirection: String, Codable, ExpressibleByArgument, CaseIterable {
    case left, right, up, down
}
