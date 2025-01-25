//
//  PermissionsManager.swift
//
//  Created by Wojciech Kulik on 25/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class PermissionsManager {
    static let shared = PermissionsManager()

    private init() {}

    func askForAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func checkForAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }
}
