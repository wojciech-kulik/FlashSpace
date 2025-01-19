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
                Button("Add") {}
                Button("Delete") {}.disabled(viewModel.selectedWorkspace == nil)
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
                Button("Add") {}.disabled(viewModel.selectedWorkspace == nil)
                Button("Delete") {}.disabled(viewModel.selectedApp == nil)
            }
        }
    }

    private var workspaceSettings: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Text("Workspace Configuration:")
                .padding(.bottom, 16.0)
                .fixedSize()

            Text("Name:")
            TextField("Name", text: $viewModel.workspaceName)
                .padding(.bottom)
            Text("Display:")
            TextField("Display", text: $viewModel.workspaceDisplay)
                .padding(.bottom)
            Text("Shortcut:")
            HotKeyControl(workspace: viewModel.selectedWorkspace)
                .padding(.bottom)
                .disabled(viewModel.selectedWorkspace == nil)

            Button("Save") {
                viewModel.selectedWorkspace = nil
            }.disabled(viewModel.selectedWorkspace == nil)

            Spacer()

            Toggle("Launch at startup", isOn: .constant(true))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    MainView()
}
