//
//  MacAppWithWorkspace.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import SwiftUI

struct MacAppWithWorkspace: Hashable, Codable {
    var app: MacApp
    var workspaceId: WorkspaceID
}

extension MacAppWithWorkspace: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MacAppWithWorkspace.self, contentType: .json)
    }
}
