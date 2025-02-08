//
//  TextField.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct PlaceholderModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled

    let placeholder: String
    let visible: Bool

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if visible, !isFocused {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .opacity(isEnabled ? 1 : 0.5)
            }
            content
                .focused($isFocused)
        }
    }
}

extension View {
    func placeholder(_ placeholder: String, visible: Bool) -> some View {
        modifier(PlaceholderModifier(placeholder: placeholder, visible: visible))
    }

    func standardPlaceholder(_ visible: Bool) -> some View {
        placeholder("(type here)", visible: visible)
    }
}
