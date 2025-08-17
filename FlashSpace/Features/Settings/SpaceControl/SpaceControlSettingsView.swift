//
//  SpaceControlSettingsView.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SpaceControlSettingsView: View {
    @StateObject var settings = AppDependencies.shared.spaceControlSettings
    @State var hasScreenRecordingPermissions = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Space Control", isOn: $settings.enableSpaceControl)
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
                        "FlashSpace requires screen recording access to show your workspaces in Space Control. " +
                            "The preview will be displayed upon first activation of the workspace."
                    )
                    .foregroundColor(.secondary)
                    .font(.callout)
                }

                Section("Shortcuts") {
                    hotkey("Toggle Space Control", for: $settings.showSpaceControl)
                }

                Section("Appearance") {
                    Toggle("Enable Transition Animation", isOn: $settings.enableSpaceControlAnimations)
                    Toggle("Enable Tiles Animation", isOn: $settings.enableSpaceControlTilesAnimations)
                    Toggle(
                        "Show Workspaces For Current Display Only",
                        isOn: $settings.spaceControlCurrentDisplayWorkspaces
                    )
                    Toggle(
                        "Update Screenshots On Open (slower)",
                        isOn: $settings.spaceControlUpdateScreenshotsOnOpen
                    )

                    HStack {
                        Text("Max Number Of Columns")
                        Spacer()
                        Text("\(settings.spaceControlMaxColumns)")
                        Stepper(
                            "",
                            value: $settings.spaceControlMaxColumns,
                            in: 2...20,
                            step: 1
                        ).labelsHidden()
                    }
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
