//
//  AppConstants.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

enum AppConstants {
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
