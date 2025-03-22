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
        if let browser = PipBrowser(rawValue: bundleId ?? "") {
            if let pipWindowTitle = browser.title {
                return title == pipWindowTitle
            } else if let pipWindowSubrole = browser.subrole {
                return subrole == pipWindowSubrole
            }
        } else if let pipApp = pipApps.first(where: { $0.bundleIdentifier == bundleId }) {
            let result = title?.range(
                of: pipApp.pipWindowTitleRegex,
                options: .regularExpression
            ) != nil

            return result
        }

        return false
    }
}
