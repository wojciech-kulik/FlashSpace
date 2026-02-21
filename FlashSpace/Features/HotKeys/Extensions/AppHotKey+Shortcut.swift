//
//  AppHotKey+Shortcut.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AppHotKey {
    func toShortcut() -> Shortcut? {
        let components = value.components(separatedBy: "+")
        let modifiers = KeyModifiersMap.toModifiers(value)

        guard let keyEquivalent = components.last,
              let rawKeyCode = KeyCodesMap[keyEquivalent] else { return nil }

        return .init(
            .init(rawValue: Int(rawKeyCode)),
            modifiers: NSEvent.ModifierFlags(rawValue: modifiers)
        )
    }
}
