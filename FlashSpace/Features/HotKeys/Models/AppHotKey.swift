//
//  AppHotKey.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

typealias RawKeyCode = UInt16
typealias RawKeyModifiers = UInt

struct AppHotKey: Codable, Hashable {
    let value: String

    init(value: String) { self.value = value }

    init(keyCode: RawKeyCode, modifiers: RawKeyModifiers) {
        let keyEquivalent = KeyCodesMap.toString[keyCode] ?? ""
        let modifiers = KeyModifiersMap.toString(modifiers)
        let result = [modifiers, keyEquivalent].filter { !$0.isEmpty }.joined(separator: "+")

        self.init(value: result)
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey { case keyCode, modifiers }

        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // v1 -> v2 Migration
            let keyCode = try container.decodeIfPresent(RawKeyCode.self, forKey: .keyCode)
            let modifiers = try container.decodeIfPresent(RawKeyModifiers.self, forKey: .modifiers)

            if let keyCode, let modifiers {
                Migrations.hotKeysMigrated = true
                self.init(keyCode: keyCode, modifiers: modifiers)
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .keyCode,
                    in: container,
                    debugDescription: "Invalid key code or modifiers"
                )
            }
        } else {
            // v2
            let container = try decoder.singleValueContainer()
            try self.init(value: container.decode(String.self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
