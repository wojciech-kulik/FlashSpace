//
//  AppHotKey+KeyboardShortcut.swift
//
//  Created by Wojciech Kulik on 31/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

extension AppHotKey {
    var toKeyboardShortcut: KeyboardShortcut? {
        let components = value.components(separatedBy: "+")
        let modifiers = toEventModifiers(value)

        guard let key = components.last,
              let keyEquivalent = stringToKeyEquivalent(key) else { return nil }

        return KeyboardShortcut(
            keyEquivalent,
            modifiers: modifiers
        )
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func stringToKeyEquivalent(_ value: String) -> KeyEquivalent? {
        guard value.count > 1 else { return KeyEquivalent(Character(value)) }

        switch value {
        case "esc", "escape": return KeyEquivalent.escape
        case "return", "enter": return KeyEquivalent.return
        case "tab": return KeyEquivalent.tab
        case "space": return KeyEquivalent.space
        case "delete", "backspace": return KeyEquivalent.delete
        case "up": return KeyEquivalent.upArrow
        case "down": return KeyEquivalent.downArrow
        case "left": return KeyEquivalent.leftArrow
        case "right": return KeyEquivalent.rightArrow
        case "home": return KeyEquivalent.home
        case "end": return KeyEquivalent.end
        default: return nil
        }
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
