//
//  Array.swift
//
//  Created by Wojciech Kulik on 27/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

extension Array {
    subscript(safe index: Index) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
        set {
            guard indices.contains(index), let newValue else { return }
            self[index] = newValue
        }
    }
}
