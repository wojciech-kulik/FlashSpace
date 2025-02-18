//
//  SpaceControlCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class SpaceControlCommands: CommandExecutor {
    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .openSpaceControl:
            if SpaceControl.isEnabled {
                SpaceControl.show()
                return CommandResponse(success: true)
            } else {
                return CommandResponse(success: false, error: "Space Control is not enabled")
            }

        default:
            return nil
        }
    }
}
