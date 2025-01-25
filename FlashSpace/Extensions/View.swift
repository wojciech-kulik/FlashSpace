//
//  View.swift
//
//  Created by Wojciech Kulik on 25/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

extension View {
    func hotkey(_ title: String, for hotKey: Binding<HotKeyShortcut?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            HotKeyControl(shortcut: hotKey).fixedSize()
        }
    }
}
