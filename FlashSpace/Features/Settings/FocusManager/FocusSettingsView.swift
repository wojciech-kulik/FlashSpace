//
//  FocusSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FocusSettingsView: View {
    @StateObject private var settings = AppDependencies.shared.focusManagerSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Focus Manager", isOn: $settings.enableFocusManagement)
            }

            Group {
                Section("Trigger when focus is changed using shortcuts") {
                    Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnFocusChange)
                }

                Section("Shortcuts") {
                    hotkey("Focus Left", for: $settings.focusLeft)
                    hotkey("Focus Right", for: $settings.focusRight)
                    hotkey("Focus Up", for: $settings.focusUp)
                    hotkey("Focus Down", for: $settings.focusDown)
                }

                Section {
                    hotkey("Focus Next App", for: $settings.focusNextWorkspaceApp)
                    hotkey("Focus Previous App", for: $settings.focusPreviousWorkspaceApp)
                }

                Section {
                    hotkey("Focus Next Window", for: $settings.focusNextWorkspaceWindow)
                    hotkey("Focus Previous Window", for: $settings.focusPreviousWorkspaceWindow)
                }

                Section("Experimental") {
                    Toggle("Focus Frontmost Window", isOn: $settings.focusFrontmostWindow)
                    Text(
                        "This is an experimental feature. It sets the focus to the frontmost window" +
                            " if two or more windows are overlapping in the pointed direction.\n\n" +
                            "It works only with directional focus shortcuts (left, right, up, down)."
                    )
                    .foregroundStyle(.secondary)
                    .font(.callout)
                }
            }
            .disabled(!settings.enableFocusManagement)
            .opacity(settings.enableFocusManagement ? 1 : 0.5)
        }
        .formStyle(.grouped)
        .navigationTitle("Focus Manager")
    }
}
