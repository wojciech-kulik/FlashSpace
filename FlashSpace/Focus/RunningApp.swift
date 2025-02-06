//
//  RunningApp.swift
//
//  Created by Wojciech Kulik on 04/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import CoreGraphics

struct RunningApp {
    struct AppWindow {
        let frame: CGRect
        let title: String
        let axWindow: AXUIElement
    }

    let name: String
    let bundleIdentifier: String
    let app: NSRunningApplication
    let windows: [AppWindow]

    init(app: NSRunningApplication) {
        self.app = app
        self.name = app.localizedName ?? ""
        self.bundleIdentifier = app.bundleIdentifier ?? ""
        self.windows = app.allWindows
            .map { AppWindow(frame: $0.frame, title: $0.window.title ?? "", axWindow: $0.window) }
            .sorted { $0.title < $1.title || $0.title == $1.title && $0.frame.minX < $1.frame.minX }
    }
}
