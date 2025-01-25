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

            Section(header: Text("Scripts To Run")) {
                HStack {
                    Text("On App Launch")
                    TextField("", text: $settings.runScriptOnLaunch)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("On Workspace Change")
                    TextField("", text: $settings.runScriptOnWorkspaceChange)
                        .foregroundColor(.secondary)
                }

                Text(
                    """
                    $WORKSPACE will be replaced with the active workspace name
                    $DISPLAY will be replaced with the corresponding display name
                    """
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Integrations")
    }
}
