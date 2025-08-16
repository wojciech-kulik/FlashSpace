//
//  Logger.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

enum Logger {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static var saveSubject = PassthroughSubject<(), Never>()

    private static var logging: AnyCancellable?

    static let lock = NSLock()
    static var logsBuffer = [String]()
    static let logsFileURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("flashspace.log")
    }()

    static func startLogging() {
        logging = saveSubject
            .eraseToAnyPublisher()
            .throttle(for: .seconds(1), scheduler: DispatchQueue.global(), latest: true)
            .sink { _ in appendLogs() }
    }

    static func log(_ message: String) {
        let dateString = dateFormatter.string(from: Date())
        print("\(dateString): \(message)")

        lock.lock()
        defer { lock.unlock() }

        logsBuffer.append("\(dateString): \(message)")
        saveSubject.send(())
    }

    static func log(_ error: Error) {
        log("\(error)")
        lock.lock()

        defer { lock.unlock() }

        logsBuffer.append("\(error)")
        saveSubject.send(())
    }

    static func appendLogs() {
        do {
            lock.lock()
            defer { lock.unlock() }

            let logEntries = logsBuffer.joined(separator: "\n")

            if FileManager.default.fileExists(atPath: logsFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logsFileURL)
                fileHandle.seekToEndOfFile()
                if let data = ("\n" + logEntries).data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try logEntries.write(to: logsFileURL, atomically: true, encoding: .utf8)
            }
            logsBuffer.removeAll()
        } catch {
            print("Failed to write logs to file: \(error)")
        }
    }
}
