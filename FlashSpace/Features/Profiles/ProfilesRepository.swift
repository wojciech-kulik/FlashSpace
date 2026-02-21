//
//  ProfilesRepository.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class ProfilesRepository: ObservableObject {
    @Published var profiles: [Profile] = [.default]
    @Published var selectedProfile: Profile = .default {
        didSet {
            guard shouldTrackProfileChange else { return }
            guard oldValue.id != selectedProfile.id else { return }
            setProfile(id: selectedProfile.id)
        }
    }

    var onProfileChange: ((Profile) -> ())?

    private var selectedProfileId: ProfileId? {
        get {
            UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKey.selectedProfileId)
                .flatMap { UUID(uuidString: $0) }
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: AppConstants.UserDefaultsKey.selectedProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKey.selectedProfileId)
            }
        }
    }

    private var shouldTrackProfileChange = true
    private lazy var settings = AppDependencies.shared.profileSettings

    init() {
        loadFromDisk()
    }

    private func loadFromDisk() {
        shouldTrackProfileChange = false
        defer { shouldTrackProfileChange = true }

        guard let config = try? ConfigSerializer.deserialize(ProfilesConfig.self, filename: "profiles"),
              !config.profiles.isEmpty else {
            return createDefaultProfile()
        }

        let migrated = migrateOldConfigIfNeeded()
        profiles = config.profiles

        let selectedProfileId = selectedProfileId
        selectedProfile = profiles.first { $0.id == selectedProfileId } ?? profiles.first ?? .default

        if migrated { saveToDisk() }
    }

    private func migrateOldConfigIfNeeded() -> Bool {
        struct OldProfilesConfig: Codable {
            let selectedProfileId: ProfileId?
        }

        if let oldConfig = try? ConfigSerializer.deserialize(OldProfilesConfig.self, filename: "profiles"),
           let profileId = oldConfig.selectedProfileId {
            selectedProfileId = profileId
            Logger.log("Migrated old profile config to new format. Profile ID: \(profileId)")

            return true
        }

        return false
    }

    private func createDefaultProfile() {
        profiles = [.init(
            id: UUID(),
            name: "Default",
            workspaces: []
        )]
        selectedProfile = profiles[0]
        saveToDisk()
    }

    private func setProfile(id: ProfileId) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }

        saveToDisk()

        onProfileChange?(profile)
        NotificationCenter.default.post(name: .profileChanged, object: nil)
        Integrations.runOnProfileChangeIfNeeded(profile: profile.name)
    }
}

extension ProfilesRepository {
    func createProfile(name: String, keepWorkspaces: Bool) {
        var workspaces = [Workspace]()

        if keepWorkspaces {
            workspaces = selectedProfile.workspaces.map { workspace in
                var newWorkspace = workspace
                newWorkspace.id = UUID()
                return newWorkspace
            }
        }

        let newProfile = Profile(id: UUID(), name: name, workspaces: workspaces)
        profiles.append(newProfile)
        profiles.sort { $0.name < $1.name }

        saveToDisk()
    }

    func renameProfile(id: ProfileId, to newName: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }

        profiles[index].name = newName
        profiles.sort { $0.name < $1.name }

        shouldTrackProfileChange = false
        selectedProfile = profiles.first { $0.id == id } ?? .default
        shouldTrackProfileChange = true

        saveToDisk()
    }

    func deleteProfile(id: ProfileId) {
        guard profiles.count > 1 else { return }

        profiles.removeAll { $0.id == id }

        if selectedProfile.id == id {
            shouldTrackProfileChange = false
            selectedProfile = profiles.first ?? .default
            shouldTrackProfileChange = true

            saveToDisk()
            setProfile(id: selectedProfile.id)
        } else {
            saveToDisk()
        }
    }

    func activateNextProfile() {
        guard let currentIndex = profiles.firstIndex(where: { $0.id == selectedProfile.id }) else { return }

        let nextIndex = (currentIndex + 1) % profiles.count
        selectedProfile = profiles[nextIndex]
    }

    func activatePreviousProfile() {
        guard let currentIndex = profiles.firstIndex(where: { $0.id == selectedProfile.id }) else { return }

        let previousIndex = (currentIndex - 1 + profiles.count) % profiles.count
        selectedProfile = profiles[previousIndex]
    }

    func updateShortcut(for profileId: ProfileId, to newShortcut: AppHotKey?) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else { return }

        profiles[index].shortcut = newShortcut

        if selectedProfile.id == profileId {
            shouldTrackProfileChange = false
            selectedProfile = profiles[index]
            shouldTrackProfileChange = true
        }

        saveToDisk()
    }

    func updateWorkspaces(_ workspaces: [Workspace]) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == selectedProfile.id }) else { return }

        profiles[profileIndex].workspaces = workspaces
        selectedProfile = profiles[profileIndex]
        saveToDisk()
    }

    func saveToDisk() {
        let config = ProfilesConfig(profiles: profiles)
        try? ConfigSerializer.serialize(filename: "profiles", config)

        selectedProfileId = selectedProfile.id
        DispatchQueue.main.async {
            AppDependencies.shared.hotKeysManager.refresh()
        }
    }

    func getHotKeys() -> [RecordedHotKey] {
        getProfileHotKeys() + getNextPrevHotKeys()
    }

    private func getProfileHotKeys() -> [RecordedHotKey] {
        profiles
            .compactMap { profile in
                profile.shortcut.flatMap {
                    RecordedHotKey(
                        name: .activateProfile(profile.id),
                        hotKey: $0,
                        action: { [weak self] in
                            self?.selectedProfile = profile

                            Toast.showWith(
                                icon: "person.crop.circle",
                                message: "\(profile.name) - Profile Activated",
                                textColor: .positive
                            )
                        }
                    )
                }
            }
    }

    private func getNextPrevHotKeys() -> [RecordedHotKey] {
        var shortcuts: [RecordedHotKey] = []

        if let nextShortcut = settings.switchToNextProfile {
            shortcuts.append(
                RecordedHotKey(
                    name: .nextProfile,
                    hotKey: nextShortcut,
                    action: { [weak self] in self?.activateNextProfile() }
                )
            )
        }

        if let prevShortcut = settings.switchToPreviousProfile {
            shortcuts.append(
                RecordedHotKey(
                    name: .previousProfile,
                    hotKey: prevShortcut,
                    action: { [weak self] in self?.activatePreviousProfile() }
                )
            )
        }

        return shortcuts
    }
}
