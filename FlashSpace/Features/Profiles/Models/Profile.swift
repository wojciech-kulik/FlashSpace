//
//  Profile.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

typealias ProfileId = UUID

struct ProfilesConfig: Codable {
    let profiles: [Profile]
}

struct Profile: Identifiable, Codable, Hashable {
    let id: ProfileId
    var name: String
    var workspaces: [Workspace]
}

extension Profile {
    static let `default` = Profile(
        id: UUID(),
        name: "Default",
        workspaces: []
    )
}
