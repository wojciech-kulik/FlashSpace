//
//  Shortcut.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

extension Shortcut {
    convenience init(code aKeyCode: KeyCode, modifierFlags aModifierFlags: NSEvent.ModifierFlags) {
        self.init(code: aKeyCode, modifierFlags: aModifierFlags, characters: nil, charactersIgnoringModifiers: nil)
    }
}

extension [(AppHotKey, () -> ())] {
    func toShortcutPairs() -> [(Shortcut, () -> ())] {
        map { ($0.0.toShortcut(), $0.1) }
            .compactMap {
                guard let shortcut = $0.0 else { return nil }
                return (shortcut, $0.1)
            }
    }
}

extension AppHotKey {
    func toShortcut() -> Shortcut? {
        let components = value.components(separatedBy: "+")
        let modifiers = KeyModifiersMap.toModifiers(value)

        guard let keyEquivalent = components.last,
              let rawKeyCode = KeyCodesMap[keyEquivalent],
              let keyCode = KeyCode(rawValue: rawKeyCode) else { return nil }

        return Shortcut(
            code: keyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifiers)
        )
    }
}
