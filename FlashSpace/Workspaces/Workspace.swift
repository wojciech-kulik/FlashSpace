//
//  Workspace.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

typealias WorkspaceID = UUID

struct Workspace: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case display
        case activateShortcut = "shortcut"
        case assignAppShortcut
        case apps
    }

    let id: WorkspaceID
    var name: String
    var display: DisplayName
    var activateShortcut: HotKeyShortcut?
    var assignAppShortcut: HotKeyShortcut?
    var apps: [String]
}
