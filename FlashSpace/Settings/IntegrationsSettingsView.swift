//
//  IntegrationsSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct IntegrationsSettingsView: View {
    @StateObject var settings = AppDependencies.shared.settingsRepository

    var body: some View {
        Form {
            Section {
                Toggle("Enable Integrations", isOn: $settings.enableIntegrations)
            }

            Section(
                header: Text("Run script on app launch:")
            ) {
                TextField("", text: $settings.runScriptOnLaunch)
            }

            Section(
                header: Text("Run script on workspace change:"),
                footer: Text(
                    """
                    $WORKSPACE will be replaced with the active workspace name
                    $DISPLAY will be replaced with the corresponding display name
                    """
                )
                .foregroundStyle(.secondary)
            ) {
                TextField("", text: $settings.runScriptOnWorkspaceChange)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Integrations")
    }
}
