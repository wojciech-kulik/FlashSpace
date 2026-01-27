//
//  View.swift
//
//  Created by Wojciech Kulik on 25/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

extension View {
    func hotkey(_ title: String, for hotKey: Binding<AppHotKey?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            HotKeyControl(shortcut: hotKey).fixedSize()
        }
    }

    @ViewBuilder
    func hidden(_ isHidden: Bool) -> some View {
        if !isHidden {
            self
        }
    }

    @ViewBuilder
    func tahoeBorder() -> some View {
        if #available(macOS 26.0, *) {
            overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        } else {
            self
        }
    }
}
