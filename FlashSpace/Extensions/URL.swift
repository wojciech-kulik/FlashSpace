//
//  URL.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension URL {
    func getLocalizedAppName() -> String {
        let appUrl = self
        let fileName = appUrl.lastPathComponent.replacingOccurrences(of: ".app", with: "")

        guard let bundle = Bundle(url: appUrl) else { return fileName }

        return bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? fileName
    }
}
