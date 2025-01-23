//
//  HotKeyShortcut.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

extension HotKeyShortcut {
    func toShortcut() -> Shortcut? {
        guard let keyCode = KeyCode(rawValue: keyCode) else { return nil }

        return Shortcut(
            code: keyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifiers)
        )
    }
}
