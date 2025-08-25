//
//  AXUIElement+PiP.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    private var pipApps: [PipApp] {
        AppDependencies.shared.workspaceSettings.pipApps
    }

    func isPictureInPicture(bundleId: String?) -> Bool {
        let browser = PipBrowser(rawValue: bundleId ?? "")
        let windowTitle = title

        if let browser {
            if let partialTitle = browser.partialTitle,
               title?.contains(partialTitle) == true {
                return true
            }

            if let pipWindowTitle = browser.title, windowTitle == pipWindowTitle {
                return true
            }

            if let pipWindowSubrole = browser.subrole, subrole == pipWindowSubrole {
                return true
            }

            if browser == .chrome,
               windowTitle?.range(of: "^Meet[^a-z]*[a-z-]{8,}", options: .regularExpression) != nil,
               document == nil || document == "about:blank" {
                return true
            }
        }

        for pipApp in pipApps.filter({ $0.bundleIdentifier == bundleId }) {
            let result = windowTitle?.range(
                of: pipApp.pipWindowTitleRegex,
                options: .regularExpression
            ) != nil

            if result { return true }
        }

        return false
    }
}
