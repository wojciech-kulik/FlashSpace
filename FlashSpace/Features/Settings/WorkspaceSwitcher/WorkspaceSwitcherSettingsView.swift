//
//  WorkspaceSwitcherSettingsView.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspaceSwitcherSettingsView: View {
    @StateObject var settings = AppDependencies.shared.workspaceSwitcherSettings
    @State var hasScreenRecordingPermissions = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Workspace Switcher", isOn: $settings.enableWorkspaceSwitcher)
            }

            Group {
                Section("Permissions") {
                    HStack {
                        if hasScreenRecordingPermissions {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Screen Recording Permission")
                            Spacer()
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Screen Recording Permission")
                            Spacer()
                            Button("Open Privacy & Security") {
                                NSWorkspace.shared.open(
                                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
                                )
                            }
                        }
                    }
                    Text(
                        "FlashSpace requires screen recording access to show workspace previews in Workspace Switcher. " +
                            "The preview will be displayed after first activation of the workspace."
                    )
                    .foregroundColor(.secondary)
                    .font(.callout)
                }

                Section("Shortcuts") {
                    VStack(alignment: .leading, spacing: 8) {
                        hotkey(
                            "Show Workspace Switcher",
                            name: .workspaceSwitcher,
                            for: $settings.showWorkspaceSwitcher
                        )

                        Text("Note: A variant with Shift modifier will be automatically registered for backward navigation.")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }

                Section("Appearance") {
                    Toggle("Show Workspace Screenshots", isOn: $settings.workspaceSwitcherShowScreenshots)
                    Toggle(
                        "Show Workspaces For Current Display Only",
                        isOn: $settings.workspaceSwitcherCurrentDisplayWorkspaces
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(
                            "Sort Workspaces By Last Activation",
                            isOn: $settings.workspaceSwitcherSortByLastActivation
                        )

                        Text(
                            "When enabled, workspaces are ordered by most recently activated first, making frequently used workspaces easier to access."
                        )
                        .foregroundColor(.secondary)
                        .font(.callout)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Visible Workspaces")
                            Spacer()
                            Text("\(settings.workspaceSwitcherVisibleWorkspaces)")
                            Stepper(
                                "",
                                value: $settings.workspaceSwitcherVisibleWorkspaces,
                                in: 1...15,
                                step: 1
                            )
                            .labelsHidden()
                        }

                        Text("If there are more workspaces than visible slots, the list scrolls automatically.")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }
            }
            .disabled(!settings.enableWorkspaceSwitcher)
            .opacity(settings.enableWorkspaceSwitcher ? 1 : 0.5)
        }
        .onAppear {
            hasScreenRecordingPermissions = PermissionsManager.shared.checkForScreenRecordingPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasScreenRecordingPermissions = PermissionsManager.shared.checkForScreenRecordingPermissions()
        }
        .onChange(of: settings.showWorkspaceSwitcher) { _, newValue in
            settings.validateShortcut(newValue)
        }
        .formStyle(.grouped)
        .navigationTitle("Workspace Switcher")
    }
}
