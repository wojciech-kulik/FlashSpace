//
//  NSRunningApplication+PiP.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    var supportsPictureInPicture: Bool {
        PipBrowser.allCases.contains { $0.bundleId == bundleIdentifier }
    }

    var isPictureInPictureActive: Bool {
        allWindows.map(\.window).contains { $0.isPictureInPicture(bundleId: bundleIdentifier) }
    }
}
