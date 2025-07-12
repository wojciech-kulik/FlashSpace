//
//  DisplayMode.swift
//
//  Created by Wojciech Kulik on 12/07/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

enum DisplayMode: String, Codable, CaseIterable {
    case `static`
    case dynamic
}

extension DisplayMode: Identifiable {
    var id: String { rawValue }

    var description: String {
        switch self {
        case .static: return "Static"
        case .dynamic: return "Dynamic"
        }
    }
}
