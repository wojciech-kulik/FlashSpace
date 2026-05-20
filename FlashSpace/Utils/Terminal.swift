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
        setEnvironment(for: task)

        task.launch()

        if synchronous {
            task.waitUntilExit()
        }
    }

    static func runScriptWithOutput(_ script: String) async -> String? {
        guard !script.isEmpty else { return nil }

        let shell = getDefaultShell() ?? "/bin/sh"
        let task = Process()
        task.launchPath = shell
        task.arguments = ["-c", script]
        setEnvironment(for: task)

        return await withCheckedContinuation { continuation in
            let pipe = Pipe()
            task.standardOutput = pipe
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(with: .success(output))
            } catch {
                Logger.log("❌ Error running script: \(error)")
                continuation.resume(with: .success(nil))
            }
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

    private static func setEnvironment(for process: Process) {
        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let commonPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/opt/homebrew/sbin",
            existingPath
        ]
        environment["PATH"] = commonPaths.joined(separator: ":")
        process.environment = environment
    }
}
