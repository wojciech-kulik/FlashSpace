//
//  AXUIElement+PiP.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension AXUIElement {
    func isPictureInPicture(bundleId: String?) -> Bool {
        guard let browser = PipBrowser(rawValue: bundleId ?? "") else { return false }

        if let pipWindowTitle = browser.title {
            return title == pipWindowTitle
        } else if let pipWindowSubrole = browser.subrole {
            return subrole == pipWindowSubrole
        }

        return false
    }
}
