//
//  String.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension String {
    static let defaultIconSymbol = "bolt.fill"

    var isNotEmpty: Bool { !isEmpty }
    var nilIfEmpty: String? { isEmpty ? nil : self }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
