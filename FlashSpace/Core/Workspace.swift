//
//  Workspace.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

typealias WorkspaceID = UUID

struct Workspace: Identifiable, Codable, Hashable {
    let id: WorkspaceID
    var name: String
    var display: String
    var shortcut: HotKeyShortcut?
    var apps: [String]
}
