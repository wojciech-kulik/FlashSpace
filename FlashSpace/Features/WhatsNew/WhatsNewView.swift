//
//  WhatsNewView.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    private let features = [
        "Added support for auto-opening specific apps.",
        "Extracted Picture-in-Picture settings to separate menu.",
        "Improved hotkeys management.",
        "Redesigned workspace configuration.",
        "Optimized apps auto-assignment."
    ]

    private let bugFixes: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(AppConstants.version)
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Features")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 16))

                                Text(feature)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .hidden(features.isEmpty)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bug Fixes")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(bugFixes.enumerated()), id: \.offset) { _, bugFix in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 16))

                                Text(bugFix)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .hidden(bugFixes.isEmpty)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
            }

            Divider()

            HStack {
                Spacer()
                Button {
                    WhatsNewManager.shared.markWhatsNewAsShown()
                    dismissWindow(id: "whats-new")
                } label: {
                    Text("Let's Go")
                        .padding(.horizontal, 8)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
        .frame(width: 600, height: 400)
        .onAppear {
            if let window = NSApplication.shared.windows.first(where: { $0.title == "FlashSpace - What's New" }) {
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
            }
        }
    }
}
