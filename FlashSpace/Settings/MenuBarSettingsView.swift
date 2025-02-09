//
//  MenuBarSettingsView.swift
//
//  Created by Wojciech Kulik on 31/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct MenuBarSettingsView: View {
    @StateObject var settings = AppDependencies.shared.settingsRepository

    var body: some View {
        Form {
            Section {
                Toggle("Show Title", isOn: $settings.showMenuBarTitle)

                HStack {
                    Text("Title Template")
                    TextField("", text: $settings.menuBarTitleTemplate)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.menuBarTitleTemplate.isEmpty)
                }
                .disabled(!settings.showMenuBarTitle)
                .opacity(settings.showMenuBarTitle ? 1 : 0.5)

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
                .opacity(settings.showMenuBarTitle ? 1 : 0.5)
            }

            Section {
                HStack {
                    Text("Display Aliases")
                    TextField("", text: $settings.menuBarDisplayAliases)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.menuBarDisplayAliases.isEmpty)
                }
                .disabled(!settings.showMenuBarTitle)
                .opacity(settings.showMenuBarTitle ? 1 : 0.5)

                Text("Example: DELL U2723QE=Secondary;Built-in Retina Display=Main")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .opacity(settings.showMenuBarTitle ? 1 : 0.5)
            }
        }
        .onChange(of: settings.showMenuBarTitle) { _, _ in
            NotificationCenter.default.post(name: .menuBarSettingsChanged, object: nil)
        }
        .onReceive(
            settings.$menuBarTitleTemplate
                .debounce(for: 1.0, scheduler: RunLoop.main)
        ) { _ in
            NotificationCenter.default.post(name: .menuBarSettingsChanged, object: nil)
        }
        .formStyle(.grouped)
        .navigationTitle("Menu Bar")
    }
}
