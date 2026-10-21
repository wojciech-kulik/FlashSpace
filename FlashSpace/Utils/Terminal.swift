//
//  Terminal.swift
//
//  Created by Wojciech Kulik on 28/04/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Terminal {
    /// Runs `script` in the user's shell.
    /// - synchronous: blocks the caller until the script exits or `timeout` elapses.
    ///   Uses a semaphore, so the run loop is NOT pumped (no re-entrant notifications).
    /// - timeout: max seconds to wait when synchronous. On expiry the process gets
    ///   SIGTERM, then SIGKILL after `killGrace` seconds.
    static func runScript(
        _ script: String,
        synchronous: Bool = false,
        timeout: TimeInterval = 2,
        killGrace: TimeInterval = 1
    ) {
        guard !script.isEmpty else { return }

        let shell = getDefaultShell() ?? "/bin/sh"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: shell)
        task.arguments = ["-c", script]
        setEnvironment(for: task)

        let finished = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in finished.signal() }

        do {
            try task.run()
        } catch {
            Logger.log("Failed to run script: \(error)")
            return
        }

        guard synchronous else { return }

        if finished.wait(timeout: .now() + timeout) == .timedOut {
            Logger.log("Script timed out after \(timeout)s, terminating: \(script)")
            task.terminate()

            if finished.wait(timeout: .now() + killGrace) == .timedOut {
                kill(task.processIdentifier, SIGKILL) // still alive, force kill
            }
        }
    }

    static func getProcessIdentifier(name: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-n", name]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            Logger.log("❌ Error running script: \(error)")
            return nil
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
