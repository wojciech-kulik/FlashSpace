//
//  URL.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension URL {
    var bundle: Bundle? { Bundle(url: self) }
    var fileName: String { lastPathComponent.replacingOccurrences(of: ".app", with: "") }
}
