//
//  ProfilesSettingsView.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct ProfilesSettingsView: View {
    @StateObject var viewModel = ProfilesSettingsViewModel()
    @StateObject var profilesRepository = AppDependencies.shared.profilesRepository

    var body: some View {
        Form {
            Section(
                header: HStack {
                    Text("Profiles")
                    Spacer()
                    Button {
                        viewModel.createNewProfile()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            ) {
                VStack(alignment: .leading) {
                    ForEach(profilesRepository.profiles) { profile in
                        HStack {
                            Button {
                                viewModel.deleteProfile(profile)
                            } label: {
                                Image(systemName: "x.circle.fill").opacity(0.8)
                            }
                            .buttonStyle(.borderless)
                            .hidden(viewModel.hideDeleteButton)

                            Button {
                                viewModel.renameProfile(profile)
                            } label: {
                                Text(profile.name)
                            }
                            .buttonStyle(.borderless)
                            .tint(.primary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter profile name:",
                userInput: $viewModel.userInput,
                isPresented: $viewModel.isInputDialogPresented
            )
        }
        .alert(
            "Are you sure you want to delete \"\(viewModel.profileToDelete)\" profile?",
            isPresented: $viewModel.isDeleteConfirmationPresented
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteConfirmed()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(
            "Do you want to copy the current workspaces to the new profile?",
            isPresented: $viewModel.isCopyChoicePresented
        ) {
            Button("Copy") { viewModel.createNewProfile(copyWorkspaces: true) }
            Button("No", role: .cancel) { viewModel.createNewProfile(copyWorkspaces: false) }
        }
        .onChange(of: viewModel.isInputDialogPresented) { _, isPresented in
            if !isPresented {
                viewModel.inputDialogDismissed()
            }
        }
        .navigationTitle("Profiles")
    }
}
