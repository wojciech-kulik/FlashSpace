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
