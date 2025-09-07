//
//  PipGoogleMeet.swift
//
//  Created by Wojciech Kulik on 26/08/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

/// Browser apps that support Google Meet Picture in Picture
enum PipGoogleMeet: String, CaseIterable {
    case chrome = "com.google.Chrome"

    var bundleId: String { rawValue }

    var titlePattern: String? {
        switch self {
        case .chrome:
            return "^Meet . .*"
        }
    }

    var document: String? {
        switch self {
        case .chrome:
            return "about:blank"
        }
    }
}
