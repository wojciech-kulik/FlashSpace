//
//  AppConstants.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

enum AppConstants {
    enum UserDefaultsKey {
        static let selectedProfileId = "selectedProfileId"
    }

    static let lastFocusedOption = MacApp(
        name: "(Last Focused)",
        bundleIdentifier: "flashspace.last-focused",
        iconPath: nil
    )

    static var version: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }

        #if DEBUG
        return version + " (debug)"
        #else
        return version
        #endif
    }
}
