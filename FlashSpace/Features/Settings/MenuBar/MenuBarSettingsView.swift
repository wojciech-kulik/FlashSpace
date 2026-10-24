//
//  MenuBarSettingsView.swift
//
//  Created by Wojciech Kulik on 31/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct MenuBarSettingsView: View {
    @StateObject var settings = AppDependencies.shared.menuBarSettings

    var body: some View {
        Form {
            mainSection
            appearanceSection
            titleSection
            aliasesSection
        }
        .formStyle(.grouped)
        .navigationTitle("Menu Bar")
    }

    private var mainSection: some View {
        Section {
            Toggle("Show in Menu Bar", isOn: $settings.showMenuBar)

            if settings.showMenuBar {
                Toggle("Show Title", isOn: $settings.showMenuBarTitle)
                Toggle("Show Icon", isOn: $settings.showMenuBarIcon)
                    .disabled(!settings.showMenuBarTitle)
            }
        }
    }

    private var titleSection: some View {
        Section("Title") {
            Toggle("Use Script to Generate Title", isOn: $settings.menuBarTitleUseScript)
                .disabled(!settings.showMenuBarTitle)
                .opacity(settings.showMenuBarTitle ? 1 : 0.5)

            if settings.menuBarTitleUseScript {
                HStack {
                    Text("Script Path")
                    TextField("", text: $settings.menuBarTitleScriptPath)
                        .foregroundColor(.secondary)
                        .standardPlaceholder(settings.menuBarTitleScriptPath.isEmpty)
                }
                .disabled(!settings.showMenuBarTitle)
                .opacity(settings.showMenuBarTitle ? 1 : 0.5)
            } else {
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
        }
        .hidden(!settings.showMenuBar)
    }

    private var aliasesSection: some View {
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
        .hidden(!settings.showMenuBar)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle("Bold Icon", isOn: $settings.menuBarBoldIcon)
            Toggle("Bold Title", isOn: $settings.menuBarBoldTitle)
            Toggle("Monospace Font", isOn: $settings.menuBarUseMonospaceFont)

            HStack {
                Text("Minimum Width")
                Spacer()
                TextField("", value: $settings.menuBarMinWidth, format: .number)
                    .onChange(of: settings.menuBarMinWidth) { oldValue, newValue in
                        guard oldValue != newValue else { return }
                        settings.menuBarMinWidth = min(MenuBarSettings.Constants.maxMinWidth, newValue)
                    }
                    .fixedSize()
                    .labelsHidden()
                Stepper(
                    "",
                    value: $settings.menuBarMinWidth,
                    in: 0...MenuBarSettings.Constants.maxMinWidth,
                    step: 1
                )
                .labelsHidden()
            }

            HStack {
                Text("Icon Spacing")
                Spacer()
                TextField("", value: $settings.menuBarIconSpacing, format: .number)
                    .onChange(of: settings.menuBarIconSpacing) { oldValue, newValue in
                        guard oldValue != newValue else { return }
                        settings.menuBarIconSpacing = min(MenuBarSettings.Constants.maxIconSpacing, newValue)
                    }
                    .fixedSize()
                    .labelsHidden()
                Stepper(
                    "",
                    value: $settings.menuBarIconSpacing,
                    in: 0...MenuBarSettings.Constants.maxIconSpacing,
                    step: 1
                )
                .labelsHidden()
            }
        }
        .hidden(!settings.showMenuBar)
    }
}
