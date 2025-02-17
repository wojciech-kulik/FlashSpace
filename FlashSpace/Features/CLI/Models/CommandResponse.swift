//
//  CommandResponse.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct CommandResponse: Codable {
    var success: Bool
    var message: String?
    var error: String?
}
