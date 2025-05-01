//
//  MacAppWithWindows.swift
//
//  Created by Wojciech Kulik on 04/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import CoreGraphics

struct MacAppWithWindows {
    struct MacAppWindow {
        let frame: CGRect
        let title: String
        let axWindow: AXUIElement
    }

    let app: NSRunningApplication
    let bundleIdentifier: BundleId

    /// Sorted by title and then by x position
    let windows: [MacAppWindow]

    init(app: NSRunningApplication) {
        self.app = app
        self.bundleIdentifier = app.bundleIdentifier ?? ""
        self.windows = app.allWindows
            .map { MacAppWindow(frame: $0.frame, title: $0.window.title ?? "", axWindow: $0.window) }
            .sorted { $0.title < $1.title || $0.title == $1.title && $0.frame.minX < $1.frame.minX }
    }
}
