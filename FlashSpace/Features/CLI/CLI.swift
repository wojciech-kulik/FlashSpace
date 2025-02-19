//
//  CLI.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum CLI {
    static var cliPath: String { Bundle.main.bundlePath + "/Contents/Resources/flashspace" }
    static var symlinkPath: String { "/usr/local/bin/flashspace" }
    static var isInstalled: Bool { FileManager.default.fileExists(atPath: symlinkPath) }

    static func install() {
        guard !isInstalled else {
            return print("✅ CLI already installed at \(symlinkPath)")
        }

        if runSudoScript("ln -s '\(cliPath)' '\(symlinkPath)'") {
            Logger.log("✅ CLI installed from \(symlinkPath)")
        }
    }

    static func uninstall() {
        guard isInstalled else { return print("✅ CLI already uninstalled") }

        if runSudoScript("rm '\(symlinkPath)'") {
            Logger.log("✅ CLI uninstalled from \(symlinkPath)")
        }
    }

    private static func runSudoScript(_ script: String) -> Bool {
        let appleScript =
            "do shell script \"sudo \(script)\" with administrator privileges"

        guard let scriptObject = NSAppleScript(source: appleScript) else {
            Logger.log("❌ Error: Failed to create AppleScript object")
            Alert.showOkAlert(title: "Error", message: "Could not run script")
            return false
        }

        var error: NSDictionary?
        scriptObject.executeAndReturnError(&error)

        if let error {
            Logger.log("❌ Error: \(error)")
            if let errorNumber = error["NSAppleScriptErrorNumber"],
               errorNumber as? NSNumber != -128,
               let errorMessage = error["NSAppleScriptErrorMessage"] as? String {
                Alert.showOkAlert(title: "Error", message: errorMessage)
            }
            return false
        }

        return true
    }
}
