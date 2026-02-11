//
// DisplayName.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit

extension DisplayName {
    static var current: Self {
        NSScreen.main?.localizedName ?? ""
    }

    static var currentOptional: Self? {
        NSScreen.main?.localizedName
    }
}
