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

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "echo 'ln -s \"\(cliPath)\" \"\(symlinkPath)\"' | sudo -S bash"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let fileHandle = pipe.fileHandleForReading
        process.launch()

        let output = String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
        Logger.log(output)
        Logger.log("✅ CLI installed at \(symlinkPath)")
    }

    static func uninstall() {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "echo 'rm \"\(symlinkPath)\"' | sudo -S bash"]

        guard isInstalled else { return print("✅ CLI already uninstalled") }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let fileHandle = pipe.fileHandleForReading
        process.launch()

        let output = String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
        Logger.log(output)
        Logger.log("✅ CLI uninstalled from \(symlinkPath)")
    }
}
