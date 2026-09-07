//
//  GeneralSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @StateObject var settings = AppDependencies.shared.generalSettings
    @State var isAutostartEnabled = false
    @State var hasAccessibilityPermissions = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at startup", isOn: $isAutostartEnabled)
                Toggle("Automatically check for updates", isOn: $settings.checkForUpdatesAutomatically)
                Button {
                    UpdatesManager.shared.checkForUpdates()
                } label: {
                    HStack {
                        Text("Check for updates")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Section("Permissions") {
                HStack {
                    if hasAccessibilityPermissions {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Accessibility Permissions")
                        Spacer()
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Accessibility Permissions")
                        Spacer()
                        Button("Open Privacy & Security") {
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            )
                        }
                    }
                }
                Text("FlashSpace requires accessibility access to manage applications.")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }

            Section("Shortcuts") {
                hotkey("Show FlashSpace", name: .showFlashSpace, for: $settings.showFlashSpace)
                hotkey("Show/Hide FlashSpace", name: .toggleFlashSpace, for: $settings.toggleFlashSpace)
                hotkey("Pause/Resume FlashSpace", name: .pauseResumeFlashSpace, for: $settings.pauseResumeFlashSpace)
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settings.showFloatingNotifications)
                Text("Some shortcuts will show a temporary notification.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .onAppear {
            isAutostartEnabled = AppDependencies.shared.autostartService.isLaunchAtLoginEnabled
            hasAccessibilityPermissions = PermissionsManager.shared.checkForAccessibilityPermissions()
        }
        .onChange(of: isAutostartEnabled) { _, enabled in
            if enabled {
                AppDependencies.shared.autostartService.enableLaunchAtLogin()
            } else {
                AppDependencies.shared.autostartService.disableLaunchAtLogin()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasAccessibilityPermissions = PermissionsManager.shared.checkForAccessibilityPermissions()
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}
