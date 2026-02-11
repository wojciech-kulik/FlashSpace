//
//  CreateWorkspaceRequest.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
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

extension CreateWorkspaceRequest {
    var toWorkspace: Workspace {
        Workspace(
            id: .init(),
            name: name,
            display: display ?? .current,
            activateShortcut: activateKey.flatMap { .init(value: $0) },
            assignAppShortcut: assignKey.flatMap { .init(value: $0) },
            apps: [],
            appToFocus: nil,
            symbolIconName: icon,
            openAppsOnActivation: openApps
        )
    }
}
