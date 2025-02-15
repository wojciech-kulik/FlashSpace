//
//  ConfigFormat.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

enum ConfigFormat: String, CaseIterable {
    case json
    case toml
    case yaml

    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .toml: return "TOML"
        case .yaml: return "YAML"
        }
    }

    var extensionName: String {
        switch self {
        case .json: return "json"
        case .toml: return "toml"
        case .yaml: return "yaml"
        }
    }
}
