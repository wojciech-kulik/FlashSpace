//
//  FocusSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FocusSettingsView: View {
    @StateObject private var settings = AppDependencies.shared.settingsRepository

    var body: some View {
        Form {
            Section {
                Toggle("Enable Focus Manager", isOn: $settings.enableFocusManagement)
            }

            Section {
                Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnFocusChange)
                Text("Triggered when focus is changed using shortcuts.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Section(header: Text("Shortcuts")) {
                hotkey("Focus Left", for: $settings.focusLeft)
                hotkey("Focus Right", for: $settings.focusRight)
                hotkey("Focus Up", for: $settings.focusUp)
                hotkey("Focus Down", for: $settings.focusDown)
            }

            Section {
                hotkey("Focus Next App", for: $settings.focusNextWorkspaceApp)
                hotkey("Focus Previous App", for: $settings.focusPreviousWorkspaceApp)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Focus Manager")
    }
}
