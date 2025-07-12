//
//  NSRunningApplication+Apps.swift
//
//  Created by Wojciech Kulik on 12/07/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var isFinder: Bool { bundleIdentifier == "com.apple.finder" }
    var isPython: Bool { bundleIdentifier == "org.python.python" }
    var isOrion: Bool { bundleIdentifier == "com.kagi.kagimacOS" }
}
