//
//  System.swift
//
//  Created by Wojciech Kulik on 01/05/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

struct AppWindow {
    let name: String
    let pid: pid_t
}

enum System {
    static var orderedWindows: [AppWindow] {
        let list = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
        guard let list else { return [] }

        return list.compactMap {
            let windowName = $0[kCGWindowName as String] as? String
            let windowOwnerPID = $0[kCGWindowOwnerPID as String] as? pid_t
            if let windowOwnerPID {
                return AppWindow(name: windowName ?? "-", pid: windowOwnerPID)
            } else {
                return nil
            }
        }
    }
}
