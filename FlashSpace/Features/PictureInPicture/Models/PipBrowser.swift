//
//  PipBrowser.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

/// Browser apps that support Picture in Picture
enum PipBrowser: String, CaseIterable {
    case chrome = "com.google.Chrome"
    case vivaldi = "com.vivaldi.Vivaldi"
    case brave = "com.brave.Browser"
    case opera = "com.operasoftware.Opera"
    case firefox = "org.mozilla.firefox"
    case zen = "app.zen-browser.zen"
    case arc = "company.thebrowser.Browser"
    case dia = "company.thebrowser.dia"
    case comet = "ai.perplexity.comet"

    var bundleId: String { rawValue }

    var title: String? {
        switch self {
        case .chrome, .vivaldi, .brave, .opera, .comet:
            return "Picture in Picture"
        case .zen, .firefox:
            return "Picture-in-Picture"
        case .arc, .dia:
            return nil
        }
    }

    var partialTitle: String? {
        switch self {
        case .chrome:
            return "about:blank "
        default:
            return nil
        }
    }

    var subrole: String? {
        switch self {
        case .arc, .dia:
            return (NSAccessibility.Subrole.systemDialog as CFString) as String
        default:
            return nil
        }
    }
}
