//
//  FocusCommands.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class FocusCommands: CommandExecutor {
    var focusManager: FocusManager { AppDependencies.shared.focusManager }

    func execute(command: CommandRequest) -> CommandResponse? {
        switch command {
        case .focusWindow(let direction):
            switch direction {
            case .left: focusManager.focusLeft()
            case .right: focusManager.focusRight()
            case .up: focusManager.focusUp()
            case .down: focusManager.focusDown()
            }
            return CommandResponse(success: true)

        case .focusNextApp:
            focusManager.nextWorkspaceApp()
            return CommandResponse(success: true)

        case .focusPreviousApp:
            focusManager.previousWorkspaceApp()
            return CommandResponse(success: true)

        case .focusNextWindow:
            focusManager.nextWorkspaceWindow()
            return CommandResponse(success: true)

        case .focusPreviousWindow:
            focusManager.previousWorkspaceWindow()
            return CommandResponse(success: true)

        default:
            return nil
        }
    }
}
