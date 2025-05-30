//
//  AXUIElement+CoreGraphics.swift
//
//  Created by Wojciech Kulik on 21/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    var cgWindowId: CGWindowID? {
        let title = title
        let pid = processId

        if let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                let windowOwnerPID = window[kCGWindowOwnerPID as String] as? pid_t
                let windowName = window[kCGWindowName as String] as? String
                let windowNumber = window[kCGWindowNumber as String] as? CGWindowID

                if title == windowName, windowOwnerPID == pid {
                    return windowNumber
                }
            }
        }

        return nil
    }

    func isBelowAnyOf(_ windows: [AXUIElement]) -> Bool {
        guard let cgWindowId, let frame else { return false }

        let otherWindows = windows.map { (id: $0.cgWindowId, window: $0) }
        let windowsAbove = CGWindowListCopyWindowInfo(.optionOnScreenAboveWindow, cgWindowId) as? [[String: Any]] ?? [[:]]
        let windowsAboveIds = Set(
            windowsAbove.compactMap { $0[kCGWindowNumber as String] as? CGWindowID }
        )

        return otherWindows.contains { otherWindowId, otherWindow in
            if let otherWindowId,
               windowsAboveIds.contains(otherWindowId),
               let otherWindowFrame = otherWindow.frame,
               frame.intersects(otherWindowFrame) {
                Logger.log("💡 Window \"\(title ?? "unknown")\" is below \"\(otherWindow.title ?? "unknown")\"")
                return true
            }

            return false
        }
    }
}
