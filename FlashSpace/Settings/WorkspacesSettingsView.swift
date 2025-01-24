//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject var settings = AppDependencies.shared.settingsRepository

    var body: some View {
        Form {
            Section(
                footer: Text("These shortcuts cycle through workspaces on the display with the cursor.")
                    .foregroundStyle(.secondary)
            ) {
                hotkey("Previous Workspace", for: $settings.switchToPreviousWorkspace)
                hotkey("Next Workspace", for: $settings.switchToNextWorkspace)
            }

            Section {
                hotkey("Unassign Focused App", for: $settings.unassignFocusedApp)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }

    private func hotkey(_ title: String, for hotKey: Binding<HotKeyShortcut?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            HotKeyControl(shortcut: hotKey).fixedSize()
        }
    }
}
