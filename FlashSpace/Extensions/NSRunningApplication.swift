//
//  NSRunningApplication.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    func getFrame() -> CGRect? {
        var windowBounds: CGRect = .zero
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        let appElement = AXUIElementCreateApplication(processIdentifier)

        // Get all windows of the application
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            NSAccessibility.Attribute.windows as CFString,
            &windowList
        )

        if result != .success {
            print("Failed to get the windows of the application.")
            return nil
        }

        guard let windows = windowList as? [AXUIElement], let mainWindow = windows.first else {
            print("No windows found (2) for: \(localizedName ?? "")")
            return nil
        }

        // swiftlint:disable force_cast
        guard AXUIElementCopyAttributeValue(
            mainWindow,
            NSAccessibility.Attribute.position as CFString,
            &positionValue
        ) == .success else { return nil }

        if let position = positionValue, AXValueGetType(position as! AXValue) == .cgPoint {
            AXValueGetValue(position as! AXValue, .cgPoint, &windowBounds.origin)
        }

        guard AXUIElementCopyAttributeValue(
            mainWindow,
            NSAccessibility.Attribute.size as CFString,
            &sizeValue
        ) == .success else { return nil }

        if let size = sizeValue, AXValueGetType(size as! AXValue) == .cgSize {
            AXValueGetValue(size as! AXValue, .cgSize, &windowBounds.size)
        }
        // swiftlint:enable force_cast

        return windowBounds.isEmpty ? nil : windowBounds
    }
}
