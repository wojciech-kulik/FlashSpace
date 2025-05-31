//
//  AppHotKey+KeyboardShortcut.swift
//
//  Created by Wojciech Kulik on 31/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

extension AppHotKey {
    var keyboardShortcut: KeyboardShortcut? {
        let components = value.components(separatedBy: "+")
        let modifiers = toEventModifiers(value)

        guard let key = components.last else { return nil }

        return KeyboardShortcut(
            KeyEquivalent(Character(key)),
            modifiers: modifiers
        )
    }

    private func toEventModifiers(_ value: String) -> EventModifiers {
        let flags = value.lowercased().split(separator: "+").map { String($0) }
        var result: EventModifiers = []

        if flags.contains("cmd") { result.insert(.command) }
        if flags.contains("ctrl") { result.insert(.control) }
        if flags.contains("opt") { result.insert(.option) }
        if flags.contains("shift") { result.insert(.shift) }

        return result
    }
}
