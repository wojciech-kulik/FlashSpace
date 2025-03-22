//
//  FloatingAppsSettingsView.swift
//
//  Created by Wojciech Kulik on 12/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FloatingAppsSettingsView: View {
    @StateObject var viewModel = FloatingAppsSettingsViewModel()
    @StateObject var settings = AppDependencies.shared.floatingAppsSettings

    var body: some View {
        Form {
            Section(header: header) {
                if settings.floatingApps.contains(where: \.bundleIdentifier.isEmpty) {
                    Text("Could not migrate some apps. Please re-add them to fix the problem.")
                        .foregroundStyle(.errorRed)
                        .font(.callout)
                }

                if settings.floatingApps.isEmpty {
                    Text("(no floating apps added)")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    appsList
                }

                Text("Floating applications remain visible across all workspaces.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Section("Shortcuts") {
                hotkey("Float Focused App", for: $settings.floatTheFocusedApp)
                hotkey("Unfloat Focused App", for: $settings.unfloatTheFocusedApp)
                hotkey("Toggle Focused App Floating", for: $settings.toggleTheFocusedAppFloating)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Floating Apps")
    }

    private var appsList: some View {
        VStack(alignment: .leading) {
            ForEach(settings.floatingApps, id: \.self) { app in
                HStack {
                    Button {
                        viewModel.deleteFloatingApp(app: app)
                    } label: {
                        Image(systemName: "x.circle.fill").opacity(0.8)
                    }.buttonStyle(.borderless)

                    Text(app.name)
                        .foregroundStyle(app.bundleIdentifier.isEmpty ? .errorRed : .primary)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Floating Apps")
            Spacer()
            Button(action: viewModel.addFloatingApp) {
                Image(systemName: "plus")
            }
        }
    }
}
