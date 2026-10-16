//
//  NSRunningApplication+PID.swift
//
//  Created by Wojciech Kulik on 16/10/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    private static var cachedProcessIdentifiers: [String: pid_t] = [:]

    var safeProcessIdentifier: pid_t {
        guard processIdentifier <= 0 else { return processIdentifier }

        guard let processName = bundleURL?.deletingPathExtension().lastPathComponent else { return -1 }

        let cachedPID = Self.cachedProcessIdentifiers[processName]
        if let cachedPID, cachedPID > 0, NSRunningApplication(processIdentifier: cachedPID) != nil {
            return cachedPID
        }

        let pid = Terminal.getProcessIdentifier(name: processName).flatMap { Int32($0) } ?? -1
        Self.cachedProcessIdentifiers[processName] = pid

        return pid
    }
}
