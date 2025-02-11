//
//  NotificationName.swift
//
//  Created by Wojciech Kulik on 22/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let appsListChanged = Notification.Name("appsListChanged")
    static let openMainWindow = Notification.Name("openMainWindow")
    static let profileChanged = Notification.Name("profileChanged")
    static let menuBarSettingsChanged = Notification.Name("menuBarSettingsChanged")
    static let workspaceChanged = Notification.Name("workspaceChanged")
}
