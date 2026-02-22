//
//  PictureInPictureSettingsView.swift
//
//  Created by Wojciech Kulik on 22/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct PictureInPictureSettingsView: View {
    @StateObject var settings = AppDependencies.shared.pictureInPictureSettings
    @StateObject var viewModel = PictureInPictureSettingsViewModel()

    var body: some View {
        Form {
            toggle
            behaviors
            pipApps
        }
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter PiP window title regex:",
                placeholder: "e.g. Meeting with.*",
                userInput: $viewModel.windowTitleRegex,
                isPresented: $viewModel.isInputDialogPresented
            )
        }
        .formStyle(.grouped)
        .navigationTitle("Workspaces")
    }

    private var toggle: some View {
        Section {
            Toggle("Enable Picture-in-Picture Support", isOn: $settings.enablePictureInPictureSupport)
        }
    }

    private var behaviors: some View {
        Section("Behaviors") {
            Toggle("Switch Workspace When Closing Picture-in-Picture", isOn: $settings.switchWorkspaceWhenPipCloses)

            HStack {
                Text("Screen Corner Offset")
                Spacer()
                Text("\(settings.pipScreenCornerOffset)")
                Stepper(
                    "",
                    value: $settings.pipScreenCornerOffset,
                    in: 1...50,
                    step: 1
                ).labelsHidden()
            }

            Text(
                "If a supported browser has Picture-in-Picture active, other " +
                    "windows will be hidden in a screen corner to keep PiP visible."
            )
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .opacity(settings.enablePictureInPictureSupport ? 1 : 0.5)
        .disabled(!settings.enablePictureInPictureSupport)
    }

    private var pipApps: some View {
        Section(header: pipAppsHeader) {
            if settings.pipApps.isEmpty {
                Text("You can apply Picture-in-Picture behavior to any app by adding it here.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                pipAppsList
            }
        }
        .opacity(settings.enablePictureInPictureSupport ? 1 : 0.5)
        .disabled(!settings.enablePictureInPictureSupport)
    }

    private var pipAppsList: some View {
        VStack(alignment: .leading) {
            ForEach(settings.pipApps, id: \.self) { app in
                HStack {
                    Button {
                        viewModel.deletePipApp(app)
                    } label: {
                        Image(systemName: "x.circle.fill").opacity(0.8)
                    }.buttonStyle(.borderless)

                    Text(app.name)
                    Spacer()
                    Text(app.pipWindowTitleRegex)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var pipAppsHeader: some View {
        HStack {
            Text("Custom Picture-in-Picture Apps")
            Spacer()
            Button {
                viewModel.addPipApp()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
