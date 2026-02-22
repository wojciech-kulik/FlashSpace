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
                .frame(maxWidth: 280)
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
            .contextMenu(forSelectionType: Workspace.self) { workspaces in
                Button("Duplicate") {
                    viewModel.duplicateWorkspaces(workspaces)
                }
                .hidden(workspaces.isEmpty)
            }
            .frame(width: 200, height: 350)
            .tahoeBorder()

            HStack {
                Button(action: viewModel.addWorkspace) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }

                Button(action: viewModel.deleteSelectedWorkspaces) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(viewModel.selectedWorkspaces.isEmpty)

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
                    app: app,
                    viewModel: viewModel
                )
            }
            .frame(width: 200, height: 350)
            .tahoeBorder()

            HStack {
                Button(action: viewModel.addApp) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }.disabled(viewModel.selectedWorkspace == nil)

                Button(action: viewModel.deleteSelectedApps) {
                    Image(systemName: "trash")
                        .frame(height: 16)
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
