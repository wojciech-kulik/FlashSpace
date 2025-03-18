//
//  NSScreen.swift
//
//  Created by Wojciech Kulik on 18/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSScreen {
    /// Returns the screen's frame where (x,y) is top-left corner relative
    /// to the main screen's top-left corner.
    var normalizedFrame: CGRect {
        let mainScreen = NSScreen.screens[0]
        return NSRect(
            x: frame.origin.x,
            y: mainScreen.frame.height - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }
}
