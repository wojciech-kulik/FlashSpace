//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject var viewModel = WorkspacesSettingsViewModel()
    @StateObject var settings = AppDependencies.shared.settingsRepository

    var body: some View {
        Form {
            Section(header: Text("Trigger when workspace is changed using shortcuts")) {
                Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnWorkspaceChange)
            }

            Section(header: Text("Shortcuts")) {
                hotkey("Unassign Focused App", for: $settings.unassignFocusedApp)
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

            Section(
                header:
                HStack {
                    Text("Floating Apps")
                    Spacer()
                    Button(action: viewModel.addFloatingApp) {
                        Image(systemName: "plus")
                    }

                    Button(action: viewModel.deleteFloatingApp) {
                        Image(systemName: "trash")
                    }.disabled(viewModel.selectedFloatingApp == nil)
                }
            ) {
                VStack(alignment: .leading) {
                    List(
                        settings.floatingApps ?? [],
                        id: \.self,
                        selection: $viewModel.selectedFloatingApp
                    ) {
                        Text($0)
                    }
                }
                hotkey("Float The Focused App", for: $settings.floatTheFocusedApp)
                hotkey("Unfloat The Focused App", for: $settings.unfloatTheFocusedApp)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }
}
