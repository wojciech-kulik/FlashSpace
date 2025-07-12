//
//  Collection.swift
//
//  Created by Wojciech Kulik on 12/07/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

extension Collection where Element: Hashable {
    var asSet: Set<Element> { Set(self) }
}
