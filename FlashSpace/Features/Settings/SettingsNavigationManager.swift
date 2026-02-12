//
//  SettingsNavigationManager.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Foundation

final class SettingsNavigationManager: ObservableObject {
    static let shared = SettingsNavigationManager()

    @Published var selectedTab = "General"

    private init() {}
}
