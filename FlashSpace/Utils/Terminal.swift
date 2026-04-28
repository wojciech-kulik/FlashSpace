//
//  Terminal.swift
//
//  Created by Wojciech Kulik on 28/04/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Terminal {
    static func runScript(_ script: String, synchronous: Bool = false) {
        guard !script.isEmpty else { return }

        let shell = getDefaultShell() ?? "/bin/sh"
        let task = Process()
        task.launchPath = shell
        task.arguments = ["-c", script]
        task.launch()

        if synchronous {
            task.waitUntilExit()
        }
    }

    static func runSudoScript(_ script: String) -> Bool {
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

    private static func getDefaultShell() -> String? {
        guard let pw = getpwuid(getuid()), let shellCString = pw.pointee.pw_shell else { return nil }

        return String(cString: shellCString)
    }
}
