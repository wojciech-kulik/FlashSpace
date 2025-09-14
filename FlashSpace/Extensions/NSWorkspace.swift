//
//  NSWorkspace.swift
//
//  Created by Wojciech Kulik on 14/09/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSWorkspace {
    var runningRegularApps: [NSRunningApplication] {
        runningApplications.filter { $0.activationPolicy == .regular }
    }
}
