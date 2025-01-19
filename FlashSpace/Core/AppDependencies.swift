//
//  AppDependencies.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

struct AppDependencies {
    static let shared = AppDependencies()

    let workspaceRepository = WorkspaceRepository()

    private init() {}
}
