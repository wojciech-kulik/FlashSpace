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
    @StateObject var viewModel = MainViewModel()

    var body: some View {
        HStack(spacing: 16.0) {
            workspaces
            assignedApps
            WorkspaceConfigurationView(viewModel: viewModel)
                .frame(maxWidth: 230)
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
                "FlashSpace introduces the new feature: command-line integration.\n\n" +
                    "It allows you to integrate FlashSpace with other apps and services.\n\n" +
                    "Go to App Settings -> CLI to learn more."
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
                $viewModel.workspaces,
                id: \.self,
                editActions: .move,
                selection: $viewModel.selectedWorkspaces
            ) { binding in
                WorkspaceCell(
                    selectedApps: $viewModel.selectedApps,
                    workspace: binding.wrappedValue
                )
            }
            .frame(width: 200, height: 350)

            HStack {
                Button(action: viewModel.addWorkspace) {
                    Image(systemName: "plus")
                }

                Button(action: viewModel.deleteSelectedWorkspaces) {
                    Image(systemName: "trash")
                }.disabled(viewModel.selectedWorkspaces.isEmpty)

                Spacer()
            }
        }
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            Text("Assigned Apps:")

            List(
                viewModel.workspaceApps ?? [],
                id: \.self,
                selection: $viewModel.selectedApps
            ) { app in
                AppCell(
                    workspaceId: viewModel.selectedWorkspace?.id ?? UUID(),
                    app: app
                )
            }
            .frame(width: 200, height: 350)

            HStack {
                Button(action: viewModel.addApp) {
                    Image(systemName: "plus")
                }.disabled(viewModel.selectedWorkspace == nil)

                Button(action: viewModel.deleteSelectedApps) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.selectedApps.isEmpty)
                .keyboardShortcut(.delete)
            }
        }
    }
}

#Preview {
    MainView()
}
