//
//  CGRect.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension CGRect {
    func getDisplay() -> String? {
        NSScreen.screens
            .first { $0.frame.contains(.init(x: self.midX, y: self.midY)) }?
            .localizedName
    }
}
