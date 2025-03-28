//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject var settings = AppDependencies.shared.workspaceSettings
    @StateObject var viewModel = WorkspaceSettingsViewModel()

    var body: some View {
        Form {
            Section("Behaviors") {
                Toggle("Center Cursor In Focused App On Workspace Change", isOn: $settings.centerCursorOnWorkspaceChange)
                Toggle("Change Workspace On App Assign", isOn: $settings.changeWorkspaceOnAppAssign)
                Toggle("Enable Workspace Transition Animation", isOn: $settings.enableWorkspaceTransitions)
                    .help("Show a brief visual transition effect when switching between workspaces")

                if settings.enableWorkspaceTransitions {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Transition Duration")
                            Text("Controls how long the transition animation lasts when switching workspaces")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Slider(value: $settings.workspaceTransitionDuration, in: 0.1...0.5, step: 0.05)
                            .frame(width: 150)
                        Text("\(settings.workspaceTransitionDuration, specifier: "%.2f")s")
                            .foregroundStyle(.secondary)
                            .frame(width: 45.0, alignment: .trailing)
                    }
                    .padding(.leading, 16)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Transition Dimming")
                            Text("Adjusts how dark the screen becomes during workspace transitions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Slider(value: $settings.workspaceTransitionDimming, in: 0.05...0.5, step: 0.05)
                            .frame(width: 150)
                        Text("\(Int(settings.workspaceTransitionDimming * 100))%")
                            .foregroundStyle(.secondary)
                            .frame(width: 45.0, alignment: .trailing)
                    }
                    .padding(.leading, 16)
                }
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

            Section("Picture-in-Picture") {
                Toggle("Enable Picture-in-Picture Support", isOn: $settings.enablePictureInPictureSupport)
                Text(
                    "If a supported browser has Picture-in-Picture active, other " +
                        "windows will be hidden in a screen corner to keep PiP visible."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }

            Section(header: pipAppsHeader) {
                if settings.pipApps.isEmpty {
                    Text("You can apply Picture-in-Picture behavior to any app by adding it here.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    pipAppsList
                }
            }
            .opacity(settings.enablePictureInPictureSupport ? 1 : 0.5)
        }
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter PiP window title regex:",
                placeholder: "e.g. Meeting with.*",
                userInput: $viewModel.windowTitleRegex,
                isPresented: $viewModel.isInputDialogPresented
            )
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }

    private var pipAppsList: some View {
        VStack(alignment: .leading) {
            ForEach(settings.pipApps, id: \.self) { app in
                HStack {
                    Button {
                        viewModel.deletePipApp(app)
                    } label: {
                        Image(systemName: "x.circle.fill").opacity(0.8)
                    }.buttonStyle(.borderless)

                    Text(app.name)
                    Spacer()
                    Text(app.pipWindowTitleRegex)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var pipAppsHeader: some View {
        HStack {
            Text("Custom Picture-in-Picture Apps")
            Spacer()
            Button {
                viewModel.addPipApp()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
