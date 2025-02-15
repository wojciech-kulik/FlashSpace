//
//  ProfilesRepository.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

typealias ProfileId = UUID

struct ProfilesConfig: Codable {
    let selectedProfileId: ProfileId
    let profiles: [Profile]
}

struct Profile: Identifiable, Codable, Hashable {
    let id: ProfileId
    var name: String
    var workspaces: [Workspace]
}

extension Profile {
    static let `default` = Profile(
        id: UUID(),
        name: "Default",
        workspaces: []
    )
}

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

    private var shouldTrackProfileChange = true

    private let profilesUrl = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashspace/profiles.json")

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        loadFromDisk()
        print(profilesUrl)
    }

    private func loadFromDisk() {
        shouldTrackProfileChange = false
        defer { shouldTrackProfileChange = true }

        guard FileManager.default.fileExists(atPath: profilesUrl.path),
              let data = try? Data(contentsOf: profilesUrl),
              let config = (try? decoder.decode(ProfilesConfig.self, from: data)),
              !config.profiles.isEmpty
        else { return createDefaultProfile() }

        profiles = config.profiles
        selectedProfile = profiles.first { $0.id == config.selectedProfileId } ?? profiles.first ?? .default
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

    func updateWorkspaces(_ workspaces: [Workspace]) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == selectedProfile.id }) else { return }

        profiles[profileIndex].workspaces = workspaces
        selectedProfile = profiles[profileIndex]
        saveToDisk()
    }

    func saveToDisk() {
        let config = ProfilesConfig(
            selectedProfileId: selectedProfile.id,
            profiles: profiles
        )

        guard let data = try? encoder.encode(config) else { return }

        try? profilesUrl.createIntermediateDirectories()
        try? data.write(to: profilesUrl)
    }
}
