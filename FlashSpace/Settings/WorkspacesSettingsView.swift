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

            Section(header: Text("Behaviors")) {
                Toggle("Change Workspace On App Assign", isOn: $settings.changeWorkspaceOnAppAssign)
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
                }
            ) {
                if settings.floatingApps?.contains(where: \.bundleIdentifier.isEmpty) == true {
                    Text("Could not migrate some apps. Please re-add them to fix the problem.")
                        .foregroundStyle(.errorRed)
                        .font(.callout)
                }

                VStack(alignment: .leading) {
                    ForEach(settings.floatingApps ?? [], id: \.self) { app in
                        HStack {
                            Button {
                                viewModel.deleteFloatingApp(app: app)
                            } label: {
                                Image(systemName: "x.circle.fill").opacity(0.8)
                            }.buttonStyle(.borderless)

                            Text(app.name)
                                .foregroundStyle(app.bundleIdentifier.isEmpty ? .errorRed : .primary)
                        }
                    }
                }
                hotkey("Float The Focused App", for: $settings.floatTheFocusedApp)
                hotkey("Unfloat The Focused App", for: $settings.unfloatTheFocusedApp)
                Text("Floating applications remain visible across all workspaces.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settings.showFloatingNotifications)
                Text("Some shortcuts will show a temporary notification.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }
}
