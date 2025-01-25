//
//  GeneralSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @StateObject var settings = AppDependencies.shared.settingsRepository
    @State var isAutostartEnabled = false
    @State var hasAccessibilityPermissions = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at startup", isOn: $isAutostartEnabled)
            }

            Section {
                Toggle("Check for updates automatically", isOn: $settings.checkForUpdatesAutomatically)
            }

            Section(header: Text("Permissions")) {
                HStack {
                    Text("Accessibility Permissions")

                    if hasAccessibilityPermissions {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
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

            Section(header: Text("Shortcuts")) {
                hotkey("Show FlashSpace", for: $settings.showFlashSpace)
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
