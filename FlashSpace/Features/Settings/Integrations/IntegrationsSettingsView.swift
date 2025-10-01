//
//  IntegrationsSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct IntegrationsSettingsView: View {
    @StateObject var settings = AppDependencies.shared.integrationsSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Integrations", isOn: $settings.enableIntegrations)
            }

            Section("Scripts To Run") {
                HStack {
                    Text("On App Launch")
                    TextField("", text: $settings.runScriptOnLaunch)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.runScriptOnLaunch.isEmpty)
                }

                HStack {
                    Text("Before Workspace Change")
                    TextField("", text: $settings.runScriptOnWorkspaceChange)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.runScriptOnWorkspaceChange.isEmpty)
                }

                HStack {
                    Text("After Workspace Change")
                    TextField("", text: $settings.runScriptAfterWorkspaceChange)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.runScriptAfterWorkspaceChange.isEmpty)
                }

                HStack {
                    Text("On Profile Change")
                    TextField("", text: $settings.runScriptOnProfileChange)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.runScriptOnProfileChange.isEmpty)
                }

                Text(
                    """
                    $WORKSPACE will be replaced with the active workspace name
                    $WORKSPACE_NUMBER will be replaced with the active workspace number
                    $DISPLAY will be replaced with the corresponding display name
                    $PROFILE will be replaced with the active profile name
                    """
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }
            .disabled(!settings.enableIntegrations)
            .opacity(settings.enableIntegrations ? 1 : 0.5)
        }
        .formStyle(.grouped)
        .navigationTitle("Integrations")
    }
}
