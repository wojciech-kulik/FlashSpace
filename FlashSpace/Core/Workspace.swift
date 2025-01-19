//
//  Workspace.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct Workspace: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let display: String
    let shortcut: String
    let apps: [String]
}
