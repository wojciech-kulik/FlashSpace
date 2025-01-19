//
//  AutostartService.swift
//
//  Created by Wojciech Kulik on 20/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ServiceManagement

final class AutostartService {
    var isLaunchAtLoginEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func enableLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }

            try SMAppService.mainApp.register()
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }

    func disableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to disable launch at login: \(error)")
        }
    }
}
