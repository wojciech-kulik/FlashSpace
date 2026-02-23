//
//  WorkspaceConfigurationView.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspaceConfigurationView: View {
    @Environment(\.openWindow) var openWindow

    @ObservedObject var viewModel: MainViewModel
    @StateObject var profilesRepository = AppDependencies.shared.profilesRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            configuration

            if viewModel.workspaces.contains(where: { $0.apps.contains(where: \.bundleIdentifier.isEmpty) }) {
                Text("Could not migrate some apps. Please re-add them to fix the problem. Please also check floating apps.")
                    .foregroundColor(.errorRed)
            }

            Spacer()
            profileAndSettings
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 18.0) {
            header
            name
            display
            focusApp

            if let selectedWorkspaceId = viewModel.selectedWorkspaceId {
                activeShortcuts(for: selectedWorkspaceId)
            } else {
                inactiveShortcut
            }

            openAppsToggle
        }
        .disabled(viewModel.selectedWorkspaceId == nil)
    }

    private var name: some View {
        HStack {
            Button {
                viewModel.isSymbolPickerPresented = true
            } label: {
                Image(systemName: viewModel.workspaceSymbolIconName ?? .defaultIconSymbol)
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
            }
            .frame(width: 32)

            TextField("Name", text: $viewModel.workspaceName)
                .onSubmit(viewModel.saveWorkspace)
        }
    }

    private var display: some View {
        Picker("Display:", selection: $viewModel.workspaceDisplay) {
            ForEach(viewModel.screens, id: \.self) {
                Text($0.padEnd(toLength: 40)).tag($0)
            }
        }
        .frame(width: 270, alignment: .leading)
        .hidden(viewModel.displayMode == .dynamic)
    }

    private var focusApp: some View {
        Picker("Focus App:", selection: $viewModel.workspaceAppToFocus) {
            ForEach(viewModel.focusAppOptions, id: \.self) {
                Text($0.name.padEnd(toLength: 40)).tag($0)
            }
        }
        .frame(width: 270, alignment: .leading)
    }

    private func activeShortcuts(for selectedWorkspaceId: WorkspaceID) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Activate Workspace:")
                HotKeyControl(
                    name: .activateWorkspace(selectedWorkspaceId),
                    shortcut: $viewModel.workspaceShortcut
                )
            }

            VStack(alignment: .leading) {
                Text("Assign App:")
                HotKeyControl(
                    name: .assignAppToWorkspace(selectedWorkspaceId),
                    shortcut: $viewModel.workspaceAssignShortcut
                )
            }
        }
    }

    private var inactiveShortcut: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Activate Workspace:")
                HotKeyControl(name: .inactiveShortcut, shortcut: .constant(nil))
                    .disabled(true)
            }

            VStack(alignment: .leading) {
                Text("Assign App:")
                HotKeyControl(name: .inactiveShortcut, shortcut: .constant(nil))
                    .disabled(true)
            }
        }
    }

    private var openAppsToggle: some View {
        HStack {
            Toggle("Open apps on activation", isOn: $viewModel.isOpenAppsOnActivationEnabled)

            Button {
                viewModel.isEditingApps = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hidden(!viewModel.isOpenAppsOnActivationEnabled || viewModel.isEditingApps)

            Button {
                viewModel.isEditingApps = false
            } label: {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hidden(!viewModel.isEditingApps)
            .offset(y: -0.5)
        }
    }

    private var header: some View {
        Text("Workspace Configuration:")
            .fixedSize()
    }

    private var profileAndSettings: some View {
        HStack {
            Picker("Profile:", selection: $profilesRepository.selectedProfile) {
                ForEach(profilesRepository.profiles) {
                    Text($0.name.padEnd(toLength: 20)).tag($0)
                }
            }

            Button(action: {
                openWindow(id: "settings")
            }, label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.primary)
            }).keyboardShortcut(",")
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
}
