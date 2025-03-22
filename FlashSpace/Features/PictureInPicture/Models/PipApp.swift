//
//  PipApp.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct PipApp: Codable, Equatable, Hashable {
    let name: String
    let bundleIdentifier: String
    let pipWindowTitleRegex: String
}
