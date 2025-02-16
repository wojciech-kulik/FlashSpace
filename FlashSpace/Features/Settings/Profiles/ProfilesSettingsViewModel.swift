//
//  ProfilesSettingsViewModel.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class ProfilesSettingsViewModel: ObservableObject {
    enum Action {
        case createProfile
        case renameProfile(ProfileId)
        case deleteProfile(ProfileId)
    }

    @Published var isInputDialogPresented = false
    @Published var isDeleteConfirmationPresented = false
    @Published var isCopyChoicePresented = false
    @Published var profileToDelete = ""
    @Published var userInput = ""

    var hideDeleteButton: Bool { profilesRepository.profiles.count == 1 }

    private var action: Action?

    private let profilesRepository = AppDependencies.shared.profilesRepository

    func createNewProfile() {
        action = .createProfile
        userInput = ""
        isInputDialogPresented = true
    }

    func createNewProfile(copyWorkspaces: Bool) {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        profilesRepository.createProfile(name: input, keepWorkspaces: copyWorkspaces)
    }

    func renameProfile(_ profile: Profile) {
        action = .renameProfile(profile.id)
        userInput = profile.name
        isInputDialogPresented = true
    }

    func deleteProfile(_ profile: Profile) {
        action = .deleteProfile(profile.id)
        profileToDelete = profile.name
        isDeleteConfirmationPresented = true
    }

    func inputDialogDismissed() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let action, !input.isEmpty else { return }

        switch action {
        case .createProfile:
            isCopyChoicePresented = true
        case .renameProfile(let id):
            profilesRepository.renameProfile(id: id, to: input)
        case .deleteProfile:
            break
        }
    }

    func deleteConfirmed() {
        guard let action else { return }

        switch action {
        case .deleteProfile(let id):
            profilesRepository.deleteProfile(id: id)
        default:
            break
        }
    }
}
