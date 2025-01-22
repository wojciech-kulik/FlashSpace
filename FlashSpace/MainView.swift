//
//  MainView.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import AppKit
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()

    var body: some View {
        HStack {
            workspaces
            assignedApps
            workspaceSettings
        }
        .padding()
        .fixedSize()
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter workspace name:",
                userInput: $viewModel.userInput,
                isPresented: $viewModel.isInputDialogPresented
            )
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
                Text(workspace.name)
            }
            .frame(width: 200, height: 400)

            HStack {
                Button("Add", action: viewModel.addWorkspace)
                Button("Delete", action: viewModel.deleteWorkspace)
                    .disabled(viewModel.selectedWorkspace == nil)
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
                Text(app)
            }
            .frame(width: 200, height: 400)

            HStack {
                Button("Add", action: viewModel.addApp)
                    .disabled(viewModel.selectedWorkspace == nil)
                Button("Delete", action: viewModel.deleteApp)
                    .disabled(viewModel.selectedApp == nil)
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
                TextField("Name", text: $viewModel.workspaceName).padding(.bottom)

                Picker("Display:", selection: $viewModel.workspaceDisplay) {
                    ForEach(viewModel.screens, id: \.self) {
                        Text($0).tag($0)
                    }
                }.padding(.bottom)

                Text("Activate Shortcut:")
                HotKeyControl(shortcut: $viewModel.workspaceShortcut).padding(.bottom)

                Text("Assign App Shortcut:")
                HotKeyControl(shortcut: $viewModel.workspaceAssignShortcut).padding(.bottom)

                Button("Save", action: viewModel.updateWorkspace)
                    .disabled(viewModel.isSaveButtonDisabled)
            }
            .disabled(viewModel.selectedWorkspace == nil)
            Spacer()

            Toggle("Launch at startup", isOn: $viewModel.isAutostartEnabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    MainView()
}
