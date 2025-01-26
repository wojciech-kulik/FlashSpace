//
//  Bundle.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension Bundle {
    var localizedAppName: String {
        localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleName"] as? String
            ?? bundleURL.fileName
    }

    var isAgent: Bool {
        infoDictionary?["LSUIElement"] as? String == "1" ||
            infoDictionary?["LSUIElement"] as? Bool == true
    }
}
