//
//  WhatsNewManager.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Foundation

final class WhatsNewManager {
    static let shared = WhatsNewManager()

    private let lastShownVersionKey = "lastShownWhatsNewVersion"

    private init() {}

    var shouldShowWhatsNew: Bool {
        let currentVersion = AppConstants.version
        let lastShownVersion = UserDefaults.standard.string(forKey: lastShownVersionKey)
        return lastShownVersion != currentVersion
    }

    func markWhatsNewAsShown() {
        let currentVersion = AppConstants.version
        UserDefaults.standard.set(currentVersion, forKey: lastShownVersionKey)
    }
}
