//
//  Logger.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum Logger {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func log(_ message: String) {
        #if DEBUG
        let dateString = dateFormatter.string(from: Date())
        print("\(dateString): \(message)")
        #endif
    }

    static func log(_ error: Error) {
        log("\(error)")
    }
}
