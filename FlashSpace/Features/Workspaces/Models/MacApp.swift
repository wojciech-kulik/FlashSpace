//
//  MacApp.swift
//
//  Created by Wojciech Kulik on 06/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

func findExecutablePath(ofPid pid: pid_t) -> String? {
    var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_SIZE))
    proc_pidpath(pid, &buffer, UInt32(MemoryLayout<CChar>.size * buffer.count))
    return String(utf8String: buffer)
}

enum MacAppIdentifier: Codable, Hashable, Equatable {
    case bundleIdentifier(String)
    case executablePath(String)

    var isEmpty: Bool {
        switch self {
        case .bundleIdentifier(let bundleIdentifier):
            return bundleIdentifier.isEmpty
        case .executablePath(let executablePath):
            return executablePath.isEmpty
        }
    }

    static func extract(from app: NSRunningApplication) -> Self {
        if let bundleIdentifier = app.bundleIdentifier {
            return .bundleIdentifier(bundleIdentifier)
        }

        if let executablePath = findExecutablePath(ofPid: app.processIdentifier) {
            return .executablePath(executablePath)
        }

        return .bundleIdentifier("")
    }
}

struct MacApp: Codable, Hashable, Equatable {
    var name: String
    var identifier: MacAppIdentifier
    var iconPath: String?

    init(
        name: String,
        bundleIdentifier: String,
        iconPath: String?
    ) {
        self.name = name
        self.identifier = .bundleIdentifier(bundleIdentifier)
        self.iconPath = iconPath
    }

    init(app: NSRunningApplication) {
        self.name = app.localizedName ?? ""
        self.identifier = MacAppIdentifier.extract(from: app)
        self.iconPath = app.iconPath
    }

    init(from decoder: any Decoder) throws {
        if let app = try? decoder.singleValueContainer().decode(String.self) {
            // V1 - migration
            let runningApp = NSWorkspace.shared.runningApplications
                .first { $0.localizedName == app }

            self.name = app

            if let runningApp {
                self.identifier = MacAppIdentifier.extract(from: runningApp)
                self.iconPath = runningApp.iconPath
            } else if let bundle = Bundle(path: "/Applications/\(app).app") {
                self.identifier = .bundleIdentifier(bundle.bundleIdentifier ?? "")
                self.iconPath = bundle.iconPath
            } else if let bundle = Bundle(path: "/System/Applications/\(app).app") {
                self.identifier = .bundleIdentifier(bundle.bundleIdentifier ?? "")
                self.iconPath = bundle.iconPath
            } else {
                self.identifier = .bundleIdentifier("")
                self.iconPath = nil
            }

            Migrations.appsMigrated = true
        } else {
            // V2
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            // TODO: THIS IS BROKEN - preserve existing encoding of bundle ID
            self.identifier = try container.decode(MacAppIdentifier.self, forKey: .identifier)
            self.iconPath = try container.decodeIfPresent(String.self, forKey: .iconPath)
        }
    }

    static func == (lhs: MacApp, rhs: MacApp) -> Bool {
        if lhs.identifier.isEmpty || rhs.identifier.isEmpty {
            return lhs.name == rhs.name
        } else {
            return lhs.identifier == rhs.identifier
        }
    }
}
