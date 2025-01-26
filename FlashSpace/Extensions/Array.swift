//
//  Array.swift
//
//  Created by Wojciech Kulik on 27/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
