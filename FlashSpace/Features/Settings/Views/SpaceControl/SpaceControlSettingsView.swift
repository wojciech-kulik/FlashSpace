//
//  SpaceControlSettingsView.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SpaceControlSettingsView: View {
    @StateObject var settings = AppDependencies.shared.settingsRepository
    @State var hasScreenRecordingPermissions = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Space Control", isOn: $settings.enableSpaceControl)
            }

            Group {
                Section("Permissions") {
                    HStack {
                        Text("Screen Recording Permission")

                        if hasScreenRecordingPermissions {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Spacer()
                            Button("Open Privacy & Security") {
                                NSWorkspace.shared.open(
                                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
                                )
                            }
                        }
                    }
                    Text(
                        "FlashSpace requires screen recording access to show your workspaces in Space Control. " +
                            "The preview will be displayed upon first activation of the workspace."
                    )
                    .foregroundColor(.secondary)
                    .font(.callout)
                }

                Section("Shortcuts") {
                    hotkey("Show Space Control", for: $settings.showSpaceControl)
                }

                Section("Appearance") {
                    Toggle("Enable Animations", isOn: $settings.enableSpaceControlAnimations)
                    Toggle(
                        "Show Workspaces For Current Display Only",
                        isOn: $settings.spaceControlCurrentDisplayWorkspaces
                    )
                }
            }
            .disabled(!settings.enableSpaceControl)
            .opacity(settings.enableSpaceControl ? 1 : 0.5)
        }
        .onAppear {
            hasScreenRecordingPermissions = PermissionsManager.shared.checkForScreenRecordingPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasScreenRecordingPermissions = PermissionsManager.shared.checkForScreenRecordingPermissions()
        }
        .formStyle(.grouped)
        .navigationTitle("Space Control")
    }
}
