//
//  AXUIElement.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    var frame: CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            self,
            NSAccessibility.Attribute.position as CFString,
            &positionValue
        ) == .success else { return nil }

        guard AXUIElementCopyAttributeValue(
            self,
            NSAccessibility.Attribute.size as CFString,
            &sizeValue
        ) == .success else { return nil }

        var windowBounds: CGRect = .zero

        // swiftlint:disable force_cast
        if let position = positionValue, AXValueGetType(position as! AXValue) == .cgPoint {
            AXValueGetValue(position as! AXValue, .cgPoint, &windowBounds.origin)
        }

        if let size = sizeValue, AXValueGetType(size as! AXValue) == .cgSize {
            AXValueGetValue(size as! AXValue, .cgSize, &windowBounds.size)
        }
        // swiftlint:enable force_cast

        return windowBounds.isEmpty ? nil : windowBounds
    }

    func focus() {
        AXUIElementPerformAction(self, NSAccessibility.Action.raise as CFString)
    }
}
