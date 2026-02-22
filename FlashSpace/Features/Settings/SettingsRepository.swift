//
//  SettingsRepository.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class SettingsRepository: ObservableObject {
    private(set) var generalSettings: GeneralSettings
    private(set) var menuBarSettings: MenuBarSettings
    private(set) var gesturesSettings: GesturesSettings
    private(set) var focusManagerSettings: FocusManagerSettings
    private(set) var workspaceSettings: WorkspaceSettings
    private(set) var pictureInPictureSettings: PictureInPictureSettings
    private(set) var floatingAppsSettings: FloatingAppsSettings
    private(set) var spaceControlSettings: SpaceControlSettings
    private(set) var integrationsSettings: IntegrationsSettings
    private(set) var profileSettings: ProfileSettings

    private lazy var allSettings: [SettingsProtocol] = [
        generalSettings,
        menuBarSettings,
        gesturesSettings,
        focusManagerSettings,
        workspaceSettings,
        pictureInPictureSettings,
        floatingAppsSettings,
        spaceControlSettings,
        integrationsSettings,
        profileSettings
    ]

    private var currentSettings = AppSettings()
    private var cancellables = Set<AnyCancellable>()
    private var shouldUpdate = false

    init(
        generalSettings: GeneralSettings,
        menuBarSettings: MenuBarSettings,
        gesturesSettings: GesturesSettings,
        focusManagerSettings: FocusManagerSettings,
        workspaceSettings: WorkspaceSettings,
        pictureInPictureSettings: PictureInPictureSettings,
        floatingAppsSettings: FloatingAppsSettings,
        spaceControlSettings: SpaceControlSettings,
        integrationsSettings: IntegrationsSettings,
        profileSettings: ProfileSettings
    ) {
        self.generalSettings = generalSettings
        self.menuBarSettings = menuBarSettings
        self.gesturesSettings = gesturesSettings
        self.focusManagerSettings = focusManagerSettings
        self.workspaceSettings = workspaceSettings
        self.pictureInPictureSettings = pictureInPictureSettings
        self.floatingAppsSettings = floatingAppsSettings
        self.spaceControlSettings = spaceControlSettings
        self.integrationsSettings = integrationsSettings
        self.profileSettings = profileSettings

        loadFromDisk()

        Publishers.MergeMany(allSettings.map(\.updatePublisher))
            .sink { [weak self] in self?.updateSettings() }
            .store(in: &cancellables)
    }

    func saveToDisk() {
        Logger.log("Saving settings to disk")
        try? ConfigSerializer.serialize(filename: "settings", currentSettings)
    }

    private func updateSettings() {
        guard shouldUpdate else { return }

        var settings = AppSettings()
        allSettings.forEach { $0.update(&settings) }
        currentSettings = settings
        saveToDisk()

        AppDependencies.shared.hotKeysManager.refresh()
        objectWillChange.send()
    }

    private func loadFromDisk() {
        Logger.log("Loading settings from disk")

        shouldUpdate = false
        defer { shouldUpdate = true }

        guard let settings = try? ConfigSerializer.deserialize(
            AppSettings.self,
            filename: "settings"
        ) else { return }

        currentSettings = settings
        allSettings.forEach { $0.load(from: settings) }
    }
}
