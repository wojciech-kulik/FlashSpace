//
//  ProfileCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class ProfileCommands: CommandExecutor {
    var profilesRepository: ProfilesRepository { AppDependencies.shared.profilesRepository }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .activateProfile(let name):
            let profile = profilesRepository.profiles.first { $0.name == name }

            if let profile {
                profilesRepository.selectedProfile = profile
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Profile not found")
            }

        case .createProfile(let name, let copy, let activate):
            profilesRepository.createProfile(name: name, keepWorkspaces: copy)
            if activate {
                profilesRepository.profiles
                    .first { $0.name == name }
                    .flatMap { profilesRepository.selectedProfile = $0 }
            }
            return CommandResponse(success: true)

        case .deleteProfile(let name):
            let profile = profilesRepository.profiles.first { $0.name == name }
            if let profile {
                profilesRepository.deleteProfile(id: profile.id)
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Profile not found")
            }

        default:
            return nil
        }
    }
}
