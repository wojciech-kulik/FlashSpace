//
//  WorkspaceTransitionView.swift
//
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//  Contribution by Sergio Patino - https://github.com/sergiopatino
//

import SwiftUI

struct WorkspaceTransitionView: View {
    let direction: TransitionDirection

    var body: some View {
        GeometryReader { _ in
            // Use a simple dark fade effect
            Color.clear
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.black.opacity(0.25))
                        .blur(radius: 0)
                )
        }
        .edgesIgnoringSafeArea(.all)
    }
}
