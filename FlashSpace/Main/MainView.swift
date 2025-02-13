//
//  MainView.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import AppKit
import SwiftUI
import SymbolPicker

struct MainView: View {
    @Environment(\.openWindow) var openWindow

    @StateObject var viewModel = MainViewModel()
    @StateObject var profilesRepository = AppDependencies.shared.profilesRepository

    var body: some View {
        HStack(spacing: 16.0) {
            workspaces
            assignedApps
            workspaceSettings.frame(maxWidth: 230)
        }
        .padding()
        .fixedSize()
        .onAppear {
            Task { await UpdatesManager.shared.autoCheckForUpdates() }
            viewModel.showWhatsNewIfNeeded()
        }
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter workspace name:",
                userInput: $viewModel.userInput,
                isPresented: $viewModel.isInputDialogPresented
            )
        }
        .alert("New Feature!", isPresented: $viewModel.isWhatsNewPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "FlashSpace introduces a new feature: Space Control.\n\n" +
                    "It allows you to quickly preview all workspace on a grid.\n\n" +
                    "Go to settings to enable it."
            )
        }
        .sheet(isPresented: $viewModel.isSymbolPickerPresented) {
            SymbolPicker(symbol: $viewModel.workspaceSymbolIconName)
        }
    }

    private var workspaces: some View {
        VStack(alignment: .leading) {
            Text("Workspaces:")

            List(
                viewModel.workspaces,
                id: \.self,
                selection: $viewModel.selectedWorkspace
            ) { workspace in
                HStack {
                    Image(systemName: workspace.symbolIconName ?? .defaultIconSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.workspaceIcon)
                    Text(workspace.name)
                        .foregroundColor(workspace.apps.contains(where: \.bundleIdentifier.isEmpty) ? .errorRed : .primary)
                }
            }
            .frame(width: 200, height: 350)

            HStack {
                Button(action: viewModel.addWorkspace) {
                    Image(systemName: "plus")
                }

                Button(action: viewModel.deleteWorkspace) {
                    Image(systemName: "trash")
                }.disabled(viewModel.selectedWorkspace == nil)

                Spacer()

                Button { viewModel.moveWorkspace(up: true) } label: {
                    Image(systemName: "arrow.up")
                }.disabled(viewModel.selectedWorkspace == nil)

                Button { viewModel.moveWorkspace(up: false) } label: {
                    Image(systemName: "arrow.down")
                }.disabled(viewModel.selectedWorkspace == nil)
            }
        }
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            Text("Assigned Apps:")

            List(
                viewModel.workspaceApps ?? [],
                id: \.self,
                selection: $viewModel.selectedApp
            ) { app in
                HStack {
                    if let iconPath = app.iconPath, let image = NSImage(byReferencingFile: iconPath) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Text(app.name)
                        .foregroundColor(app.bundleIdentifier.isEmpty ? .errorRed : .primary)
                }
            }
            .frame(width: 200, height: 350)

            HStack {
                Button(action: viewModel.addApp) {
                    Image(systemName: "plus")
                }.disabled(viewModel.selectedWorkspace == nil)

                Button(action: viewModel.deleteApp) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.selectedApp == nil)
                .keyboardShortcut(.delete)
            }
        }
    }

    private var workspaceSettings: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            VStack(alignment: .leading, spacing: 1.0) {
                Text("Workspace Configuration:")
                    .padding(.bottom, 16.0)
                    .fixedSize()

                Text("Name:")
                TextField("Name", text: $viewModel.workspaceName)
                    .onSubmit(viewModel.saveWorkspace)
                    .padding(.bottom)

                Picker("Display:", selection: $viewModel.workspaceDisplay) {
                    ForEach(viewModel.screens, id: \.self) {
                        Text($0).tag($0)
                    }
                }.padding(.bottom)

                Picker("Focus App:", selection: $viewModel.workspaceAppToFocus) {
                    ForEach(viewModel.focusAppOptions, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }.padding(.bottom)

                HStack {
                    Text("Menu Bar Icon:")
                    Button {
                        viewModel.isSymbolPickerPresented = true
                    } label: {
                        Image(systemName: viewModel.workspaceSymbolIconName ?? .defaultIconSymbol)
                            .frame(maxWidth: .infinity)
                    }
                }.padding(.bottom)

                Text("Activate Shortcut:")
                HotKeyControl(shortcut: $viewModel.workspaceShortcut).padding(.bottom)

                Text("Assign App Shortcut:")
                HotKeyControl(shortcut: $viewModel.workspaceAssignShortcut).padding(.bottom)
            }
            .disabled(viewModel.selectedWorkspace == nil)

            if viewModel.workspaces.contains(where: { $0.apps.contains(where: \.bundleIdentifier.isEmpty) }) {
                Text("Could not migrate some apps. Please re-add them to fix the problem. Please also check floating apps.")
                    .foregroundColor(.errorRed)
            }

            Spacer()

            HStack {
                Picker("Profile:", selection: $profilesRepository.selectedProfile) {
                    ForEach(profilesRepository.profiles) {
                        Text($0.name).tag($0)
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
}

#Preview {
    MainView()
}
