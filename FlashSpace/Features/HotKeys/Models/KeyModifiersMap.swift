//
//  KeyModifiersMap.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

enum KeyModifiersMap {
    static func toString(_ value: RawKeyModifiers) -> String {
        let flags = NSEvent.ModifierFlags(rawValue: value)
        var result: [String] = []

        if flags.contains(.command) { result.append("cmd") }
        if flags.contains(.control) { result.append("ctrl") }
        if flags.contains(.option) { result.append("opt") }
        if flags.contains(.shift) { result.append("shift") }

        return result.joined(separator: "+")
    }

    static func toModifiers(_ value: String) -> RawKeyModifiers {
        let flags = value.lowercased().split(separator: "+").map { String($0) }
        var result: RawKeyModifiers = 0

        if flags.contains("cmd") { result |= NSEvent.ModifierFlags.command.rawValue }
        if flags.contains("ctrl") { result |= NSEvent.ModifierFlags.control.rawValue }
        if flags.contains("opt") { result |= NSEvent.ModifierFlags.option.rawValue }
        if flags.contains("shift") { result |= NSEvent.ModifierFlags.shift.rawValue }

        return result
    }
}
