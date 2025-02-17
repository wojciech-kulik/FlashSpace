//
//  CommandRequest.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum CommandRequest: Codable {
    case activateWorkspace(name: String)
    case nextWorkspace
    case previousWorkspace

    case focusWindow(direction: FocusDirection)
    case focusNextWindow
    case focusPreviousWindow
    case focusNextApp
    case focusPreviousApp
}

enum FocusDirection: String, Codable {
    case left, right, up, down
}
