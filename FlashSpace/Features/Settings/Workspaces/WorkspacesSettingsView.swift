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
            displays
            generalBehaviors
            workspaceActivationBehaviors
            shortcuts
            cycleShortcuts
            alternativeDisplays
            cornerApps
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }

    private var displays: some View {
        Section("Displays") {
            Picker("Display Assignment Mode", selection: $settings.displayMode) {
                ForEach(DisplayMode.allCases) { action in
                    Text(action.description).tag(action)
                }
            }

            Text("Static Mode requires you to manually assign workspaces to displays.\n\n" +
                "Dynamic Mode automatically assigns workspaces to displays " +
                "based on where your applications are located. In this mode, a single workspace can span across multiple displays."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private var generalBehaviors: some View {
        Section("Behaviors - General") {
            Toggle("Switch Workspace On App Focus", isOn: $settings.activeWorkspaceOnFocusChange)
            Toggle("Switch Workspace On App Assignment", isOn: $settings.changeWorkspaceOnAppAssign)
            Toggle("Auto-Assign Focused Apps To Active Workspace", isOn: $settings.autoAssignAppsToWorkspaces)
            if settings.autoAssignAppsToWorkspaces {
                Toggle("Apply To Currently Assigned Apps", isOn: $settings.autoAssignAlreadyAssignedApps)
                    .padding(.leading, 16)
            }
        }
    }

    private var workspaceActivationBehaviors: some View {
        Section("Behaviors - Workspace Activation") {
            Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnWorkspaceChange)
            Toggle("Keep Unassigned Apps", isOn: $settings.keepUnassignedAppsOnSwitch)
            Toggle("Restore Hidden Apps", isOn: $settings.restoreHiddenAppsOnSwitch)
                .help("Restores hidden apps, even if they were hidden manually")
            Toggle(
                "Return To Previous Workspace On Second Activation",
                isOn: $settings.showRecentWorkspaceWhenActivatedTwice
            )
            .help(
                "When enabled, activating the current workspace twice will switch to the most recently used workspace instead"
            )
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
    }

    private var shortcuts: some View {
        Section("Shortcuts") {
            hotkey("Assign Visible Apps (to active workspace)", name: .assignVisibleApps, for: $settings.assignVisibleApps)
            hotkey("Assign Focused App (to active workspace)", name: .assignFocusedApp, for: $settings.assignFocusedApp)
            hotkey("Unassign Focused App", name: .unassignFocusedApp, for: $settings.unassignFocusedApp)
            hotkey("Toggle Focused App Assignment", name: .toggleFocusedAppAssignment, for: $settings.toggleFocusedAppAssignment)
            hotkey("Show Unassigned Apps", name: .showUnassignedApps, for: $settings.showUnassignedApps)
            hotkey("Hide Unassigned Apps", name: .hideUnassignedApps, for: $settings.hideUnassignedApps)
            hotkey("Hide All Apps", name: .hideAllApps, for: $settings.hideAllApps)
        }
    }

    private var cycleShortcuts: some View {
        Section {
            hotkey("Recent Workspace", name: .recentWorkspace, for: $settings.switchToRecentWorkspace)
            hotkey("Previous Workspace", name: .previousWorkspace, for: $settings.switchToPreviousWorkspace)
            hotkey("Next Workspace", name: .nextWorkspace, for: $settings.switchToNextWorkspace)
            Toggle("Loop Workspaces", isOn: $settings.loopWorkspaces)
            Toggle("Loop On All Displays", isOn: $settings.loopWorkspacesOnAllDisplays)
            Toggle("Start On Cursor Screen", isOn: $settings.switchWorkspaceOnCursorScreen)
            Toggle("Skip Empty Workspaces", isOn: $settings.skipEmptyWorkspacesOnSwitch)
            Text(
                "These shortcuts allow you to cycle through workspaces on the display where the cursor is currently located."
            )
            .foregroundStyle(.secondary)
            .font(.callout)
        }
    }

    private var alternativeDisplays: some View {
        Section("Displays Customization") {
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
        .hidden(settings.displayMode == .dynamic)
    }

    private var cornerApps: some View {
        Section(header: cornerHiddenAppsHeader) {
            if settings.cornerHiddenApps.isEmpty {
                Text(
                    "Apps added here will be hidden in the corner during workspace switches instead of being completely hidden."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            } else {
                cornerHiddenAppsList
            }
        }
    }

    private var cornerHiddenAppsList: some View {
        VStack(alignment: .leading) {
            ForEach(settings.cornerHiddenApps, id: \.self) { app in
                HStack {
                    Button {
                        viewModel.deleteCornerHiddenApp(app)
                    } label: {
                        Image(systemName: "x.circle.fill").opacity(0.8)
                    }.buttonStyle(.borderless)

                    Text(app.name)
                    Spacer()
                }
            }
        }
    }

    private var cornerHiddenAppsHeader: some View {
        HStack {
            Text("Corner Hidden Apps")
            Spacer()
            Button {
                viewModel.addCornerHiddenApp()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
