//
//  AXUIElement+GetSet.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    func getAttribute<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(self, attribute as CFString, &value)

        return value as? T
    }

    func setAttribute(_ attribute: NSAccessibility.Attribute, value: some Any) {
        AXUIElementSetAttributeValue(self, attribute as CFString, value as CFTypeRef)
    }
}
