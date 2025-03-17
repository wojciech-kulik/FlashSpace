//
//  KeyCodesMap.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Carbon

enum KeyCodesMap {
    private(set) static var toKeyCode = create()

    static let toString = toKeyCode.reduce(into: [RawKeyCode: String]()) { result, pair in
        result[pair.value] = pair.key

        for (alias, keyCode) in getAliases() {
            result[keyCode] = alias
        }
    }

    static subscript(key: String) -> RawKeyCode? { toKeyCode[key] }

    static func refresh() {
        toKeyCode = create()
    }

    private static func create() -> [String: RawKeyCode] {
        var stringToKeyCodes: [String: RawKeyCode] = [:]
        var currentKeyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        var rawLayoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)
        if rawLayoutData == nil {
            currentKeyboard = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeUnretainedValue()
            rawLayoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)
        }

        let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
        let layout: UnsafePointer<UCKeyboardLayout> = unsafeBitCast(
            CFDataGetBytePtr(layoutData),
            to: UnsafePointer<UCKeyboardLayout>.self
        )

        var keysDown: UInt32 = 0
        var chars: [UniChar] = [0, 0, 0, 0]
        var realLength = 0

        for keyCode in 0..<128 {
            switch keyCode {
            case kVK_ANSI_Keypad0, kVK_ANSI_Keypad1, kVK_ANSI_Keypad2, kVK_ANSI_Keypad3,
                 kVK_ANSI_Keypad4, kVK_ANSI_Keypad5, kVK_ANSI_Keypad6, kVK_ANSI_Keypad7,
                 kVK_ANSI_Keypad8, kVK_ANSI_Keypad9,
                 kVK_ANSI_KeypadMinus, kVK_ANSI_KeypadMultiply, kVK_ANSI_KeypadDivide,
                 kVK_ANSI_KeypadDecimal, kVK_ANSI_KeypadClear, kVK_ANSI_KeypadEnter,
                 kVK_ANSI_KeypadEquals, kVK_ANSI_KeypadPlus:
                continue
            default: break
            }

            UCKeyTranslate(
                layout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &keysDown,
                chars.count,
                &realLength,
                &chars
            )

            let string = CFStringCreateWithCharacters(kCFAllocatorDefault, chars, realLength) as String
            if !stringToKeyCodes.keys.contains(string) {
                stringToKeyCodes[string] = UInt16(keyCode)
            }
        }

        let aliases = getAliases()
        for (alias, keyCode) in aliases {
            stringToKeyCodes[alias] = keyCode
        }

        return stringToKeyCodes
    }

    private static func getAliases() -> [String: RawKeyCode] {
        [
            "space": UInt16(kVK_Space),
            "enter": UInt16(kVK_Return),
            "up": UInt16(kVK_UpArrow),
            "right": UInt16(kVK_RightArrow),
            "down": UInt16(kVK_DownArrow),
            "left": UInt16(kVK_LeftArrow),
            "delete": UInt16(kVK_Delete),
            "forward-delete": UInt16(kVK_ForwardDelete),
            "escape": UInt16(kVK_Escape),
            "tab": UInt16(kVK_Tab),
            "capslock": UInt16(kVK_CapsLock),
            "f1": UInt16(kVK_F1),
            "f2": UInt16(kVK_F2),
            "f3": UInt16(kVK_F3),
            "f4": UInt16(kVK_F4),
            "f5": UInt16(kVK_F5),
            "f6": UInt16(kVK_F6),
            "f7": UInt16(kVK_F7),
            "f8": UInt16(kVK_F8),
            "f9": UInt16(kVK_F9),
            "f10": UInt16(kVK_F10),
            "f11": UInt16(kVK_F11),
            "f12": UInt16(kVK_F12),
            "num0": UInt16(kVK_ANSI_Keypad0),
            "num1": UInt16(kVK_ANSI_Keypad1),
            "num2": UInt16(kVK_ANSI_Keypad2),
            "num3": UInt16(kVK_ANSI_Keypad3),
            "num4": UInt16(kVK_ANSI_Keypad4),
            "num5": UInt16(kVK_ANSI_Keypad5),
            "num6": UInt16(kVK_ANSI_Keypad6),
            "num7": UInt16(kVK_ANSI_Keypad7),
            "num8": UInt16(kVK_ANSI_Keypad8),
            "num9": UInt16(kVK_ANSI_Keypad9),
            "num-plus": UInt16(kVK_ANSI_KeypadPlus),
            "num-minus": UInt16(kVK_ANSI_KeypadMinus),
            "num-multiply": UInt16(kVK_ANSI_KeypadMultiply),
            "num-divide": UInt16(kVK_ANSI_KeypadDivide),
            "num-clear": UInt16(kVK_ANSI_KeypadClear),
            "num-enter": UInt16(kVK_ANSI_KeypadEnter),
            "num-equals": UInt16(kVK_ANSI_KeypadEquals),
            "num-decimal": UInt16(kVK_ANSI_KeypadDecimal)
        ]
    }
}
