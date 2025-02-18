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
        case .changeProfile(let name):
            let profile = profilesRepository.profiles.first { $0.name == name }

            if let profile {
                profilesRepository.selectedProfile = profile
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Profile not found")
            }

        default:
            return nil
        }
    }
}
