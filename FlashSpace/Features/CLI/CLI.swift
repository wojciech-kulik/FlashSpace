//
//  CLI.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum CLI {
    static var cliPath: String { Bundle.main.bundlePath + "/Contents/Resources/flashspace" }
    static var symlinkDirPath: String { "/usr/local/bin" }
    static var symlinkPath: String { "/usr/local/bin/flashspace" }
    static var homebrewSymlinkPath: String { "/opt/homebrew/bin/flashspace" }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: symlinkPath) ||
            FileManager.default.fileExists(atPath: homebrewSymlinkPath)
    }

    static func install() {
        guard !isInstalled else {
            return print("✅ CLI already installed at \(symlinkPath)")
        }

        if Terminal.runSudoScript("ln -s '\(cliPath)' '\(symlinkPath)'") {
            Logger.log("✅ CLI installed from \(symlinkPath)")
        }
    }

    static func uninstall() {
        guard isInstalled else { return print("✅ CLI already uninstalled") }

        if Terminal.runSudoScript("rm -f '\(symlinkPath)' '\(homebrewSymlinkPath)'") {
            Logger.log("✅ CLI uninstalled")
        }
    }
}
