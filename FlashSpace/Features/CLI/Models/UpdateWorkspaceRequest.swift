//
//  UpdateWorkspaceRequest.swift
//
//  Created by Wojciech Kulik on 02/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct UpdateWorkspaceRequest: Codable {
    enum Display: Codable {
        case active
        case name(String)
    }

    let name: String?
    let display: Display?
}
