//
//  SettingsRepository.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct AppSettings: Codable {
    var enableFocusManagement: Bool?
    var focusLeft: HotKeyShortcut?
    var focusRight: HotKeyShortcut?
    var focusUp: HotKeyShortcut?
    var focusDown: HotKeyShortcut?
    var focusNextWorkspaceApp: HotKeyShortcut?
    var focusPreviousWorkspaceApp: HotKeyShortcut?
}

final class SettingsRepository: ObservableObject {
    @Published var enableFocusManagement: Bool = true {
        didSet { updateSettings() }
    }

    @Published var focusLeft: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusRight: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusUp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusDown: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusNextWorkspaceApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusPreviousWorkspaceApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    private var currentSettings = AppSettings()
    private var shouldUpdate = false

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dataUrl = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashspace/settings.json")

    init() {
        loadFromDisk()
    }

    private func updateSettings() {
        guard shouldUpdate else { return }

        currentSettings = AppSettings(
            enableFocusManagement: enableFocusManagement,
            focusLeft: focusLeft,
            focusRight: focusRight,
            focusUp: focusUp,
            focusDown: focusDown,
            focusNextWorkspaceApp: focusNextWorkspaceApp,
            focusPreviousWorkspaceApp: focusPreviousWorkspaceApp
        )
        saveToDisk()
        AppDependencies.shared.hotKeysManager.refresh()
    }

    private func saveToDisk() {
        guard let data = try? encoder.encode(currentSettings) else { return }
        try? data.write(to: dataUrl)
    }

    private func loadFromDisk() {
        shouldUpdate = false
        defer { shouldUpdate = true }

        guard FileManager.default.fileExists(atPath: dataUrl.path) else { return }
        guard let data = try? Data(contentsOf: dataUrl) else { return }
        guard let settings = try? decoder.decode(AppSettings.self, from: data) else { return }

        currentSettings = settings

        enableFocusManagement = settings.enableFocusManagement ?? true
        focusLeft = settings.focusLeft
        focusRight = settings.focusRight
        focusUp = settings.focusUp
        focusDown = settings.focusDown
        focusNextWorkspaceApp = settings.focusNextWorkspaceApp
        focusPreviousWorkspaceApp = settings.focusPreviousWorkspaceApp
    }
}
