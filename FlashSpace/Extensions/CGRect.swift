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
            .first { $0.normalizedFrame.contains(.init(x: self.midX, y: self.midY)) }?
            .localizedName
    }

    func verticalIntersect(with rect: CGRect) -> Bool {
        var rect = rect
        rect.origin.x = origin.x

        return intersects(rect)
    }

    func horizontalIntersect(with rect: CGRect) -> Bool {
        var rect = rect
        rect.origin.y = origin.y

        return intersects(rect)
    }

    func distance(to rect: CGRect) -> CGFloat {
        let x = midX - rect.midX
        let y = midY - rect.midY

        return sqrt(x * x + y * y)
    }
}
