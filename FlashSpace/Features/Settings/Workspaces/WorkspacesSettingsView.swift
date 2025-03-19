//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject var settings = AppDependencies.shared.workspaceSettings

    var body: some View {
        Form {
            Section("Trigger when workspace is changed using shortcuts") {
                Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnWorkspaceChange)
            }

            Section("Behaviors") {
                Toggle("Change Workspace On App Assign", isOn: $settings.changeWorkspaceOnAppAssign)
                Toggle("Enable Picture in Picture Support", isOn: $settings.enablePictureInPictureSupport)
                Text(
                    "When enabled, if a supported browser has Picture-in-Picture (PiP) active, other " +
                        "windows will be hidden in a screen corner to keep PiP visible."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }

            Section("Shortcuts") {
                hotkey("Assign Focused App (to active workspace)", for: $settings.assignFocusedApp)
                hotkey("Unassign Focused App", for: $settings.unassignFocusedApp)
                hotkey("Toggle Focused App Assignment", for: $settings.toggleFocusedAppAssignment)
            }

            Section {
                hotkey("Recent Workspace", for: $settings.switchToRecentWorkspace)
                hotkey("Previous Workspace", for: $settings.switchToPreviousWorkspace)
                hotkey("Next Workspace", for: $settings.switchToNextWorkspace)
                Text(
                    "These shortcuts allow you to cycle through workspaces on the display where the cursor is currently located."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }

            Section {
                HStack {
                    Text("Alternative Displays")
                    TextField("", text: $settings.alternativeDisplays)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.alternativeDisplays.isEmpty)
                }

                Text(
                    """
                    Example: DELL XYZ=Benq ABC;LG 123=DELL XYZ

                    This setting is useful if you want to use the same configuration for different displays.
                    You can tell FlashSpace which display should be used if the selected one is not connected.

                    If only one display is connected, it will always act as the fallback.
                    """
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }
}
