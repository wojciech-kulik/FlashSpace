//
//  MacApp.swift
//
//  Created by Wojciech Kulik on 06/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

typealias BundleId = String

struct MacApp: Codable, Hashable, Equatable {
    var name: String
    var bundleIdentifier: BundleId
    var iconPath: String?

    init(
        name: String,
        bundleIdentifier: BundleId,
        iconPath: String?
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.iconPath = iconPath
    }

    init(app: NSRunningApplication) {
        self.name = app.localizedName ?? ""
        self.bundleIdentifier = app.bundleIdentifier ?? ""
        self.iconPath = app.iconPath
    }

    init(from decoder: any Decoder) throws {
        if let app = try? decoder.singleValueContainer().decode(String.self) {
            // V1 - migration
            let runningApp = NSWorkspace.shared.runningApplications
                .first { $0.localizedName == app }

            self.name = app

            if let runningApp {
                self.bundleIdentifier = runningApp.bundleIdentifier ?? ""
                self.iconPath = runningApp.iconPath
            } else if let bundle = Bundle(path: "/Applications/\(app).app") {
                self.bundleIdentifier = bundle.bundleIdentifier ?? ""
                self.iconPath = bundle.iconPath
            } else if let bundle = Bundle(path: "/System/Applications/\(app).app") {
                self.bundleIdentifier = bundle.bundleIdentifier ?? ""
                self.iconPath = bundle.iconPath
            } else {
                self.bundleIdentifier = ""
                self.iconPath = nil
            }

            Migrations.appsMigrated = true
        } else {
            // V2
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
            self.iconPath = try container.decodeIfPresent(String.self, forKey: .iconPath)
        }
    }

    static func == (lhs: MacApp, rhs: MacApp) -> Bool {
        if lhs.bundleIdentifier.isEmpty || rhs.bundleIdentifier.isEmpty {
            return lhs.name == rhs.name
        } else {
            return lhs.bundleIdentifier == rhs.bundleIdentifier
        }
    }
}

extension MacApp {
    var isFinder: Bool {
        bundleIdentifier == "com.apple.finder"
    }
}
