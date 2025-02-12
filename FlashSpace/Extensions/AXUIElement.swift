//
//  AXUIElement.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    var id: String? { getAttribute(.identifier) }
    var title: String? { getAttribute(.title) }
    var isMain: Bool { getAttribute(.main) == true }
    var role: String? { getAttribute(.role) }
    var subrole: String? { getAttribute(.subrole) }

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

    func isPictureInPicture(bundleId: String?) -> Bool {
        guard let browser = PipBrowser(rawValue: bundleId ?? "") else { return false }

        if let pipWindowTitle = browser.title {
            return title == pipWindowTitle
        } else if let pipWindowSubrole = browser.subrole {
            return subrole == pipWindowSubrole
        }

        return false
    }

    func focus() {
        AXUIElementPerformAction(self, NSAccessibility.Action.raise as CFString)
    }

    func minimize(_ minimize: Bool) {
        AXUIElementSetAttributeValue(
            self,
            NSAccessibility.Attribute.minimized as CFString,
            minimize ? kCFBooleanTrue : kCFBooleanFalse
        )
    }

    func getAttribute<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(self, attribute as CFString, &value)

        return value as? T
    }
}
