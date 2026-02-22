//
//  HotKeysManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import InputMethodKit
import KeyboardShortcuts

final class HotKeysManager {
    private(set) var allHotKeys: [(scope: String, hotKey: AppHotKey)] = []

    private var cancellables = Set<AnyCancellable>()

    private let workspaceHotKeys: WorkspaceHotKeys
    private let floatingAppsHotKeys: FloatingAppsHotKeys
    private let focusManager: FocusManager
    private let settingsRepository: SettingsRepository
    private let profilesRepository: ProfilesRepository

    init(
        workspaceHotKeys: WorkspaceHotKeys,
        floatingAppsHotKeys: FloatingAppsHotKeys,
        focusManager: FocusManager,
        settingsRepository: SettingsRepository,
        profilesRepository: ProfilesRepository
    ) {
        self.workspaceHotKeys = workspaceHotKeys
        self.floatingAppsHotKeys = floatingAppsHotKeys
        self.focusManager = focusManager
        self.settingsRepository = settingsRepository
        self.profilesRepository = profilesRepository

        observe()

        KeyboardShortcuts.onPausedKeyDown = { [weak self] shortcut in
            guard let self else { return }

            if let conflict = allHotKeys.first(where: { $0.hotKey.toShortcut() == shortcut })?.scope {
                Alert.showOkAlert(
                    title: "Conflict",
                    message: "This shortcut is already assigned within the \(conflict) scope."
                )
            }
        }
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func enableAll() {
        KeyboardShortcuts.removeAllHandlers()
        allHotKeys.removeAll()

        let addShortcut = { (title: String, hotKey: RecordedHotKey) in
            if let shortcut = hotKey.hotKey.toShortcut() {
                HotKeyControl.isListeningForChanges = false
                hotKey.name.shortcut = shortcut
                HotKeyControl.isListeningForChanges = true
                KeyboardShortcuts.onKeyDown(for: hotKey.name, action: hotKey.action)
            }

            self.allHotKeys.append((title, hotKey.hotKey))
        }

        // Workspaces
        if !settingsRepository.workspaceSettings.isPaused {
            for shortcut in workspaceHotKeys.getHotKeys() {
                addShortcut("Workspace", shortcut)
            }
        }

        // Profiles
        for shortcut in profilesRepository.getHotKeys() {
            addShortcut("Profile", shortcut)
        }

        // Floating Apps
        for shortcut in floatingAppsHotKeys.getHotKeys() {
            addShortcut("Floating Apps", shortcut)
        }

        // Focus Manager
        for shortcut in focusManager.getHotKeys() {
            addShortcut("Focus Manager", shortcut)
        }

        // General
        if let showHotKey = settingsRepository.generalSettings.showFlashSpace {
            let action = {
                guard !SpaceControl.isVisible else { return }
                NotificationCenter.default.post(name: .openMainWindow, object: nil)
            }

            let shortcut = RecordedHotKey(
                name: .showFlashSpace,
                hotKey: showHotKey,
                action: action
            )
            addShortcut("General", shortcut)
        }

        if let toggleHotKey = settingsRepository.generalSettings.toggleFlashSpace {
            let action = {
                guard !SpaceControl.isVisible else { return }

                let visibleAppWindows = NSApp.windows
                    .filter(\.isVisible)
                    .filter { $0.identifier?.rawValue == "main" || $0.identifier?.rawValue == "settings" }

                if visibleAppWindows.isEmpty {
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
                } else {
                    visibleAppWindows.forEach { $0.close() }
                }
            }
            let shortcut = RecordedHotKey(
                name: .toggleFlashSpace,
                hotKey: toggleHotKey,
                action: action
            )
            addShortcut("General", shortcut)
        }

        if let pauseResumeHotKey = settingsRepository.generalSettings.pauseResumeFlashSpace {
            let action = {
                AppDependencies.shared.workspaceManager.togglePauseWorkspaceManagement()
                let isPaused = AppDependencies.shared.workspaceSettings.isPaused

                Toast.showWith(
                    icon: isPaused ? "pause.circle" : "play.circle",
                    message: isPaused ? "FlashSpace Paused" : "FlashSpace Resumed",
                    textColor: isPaused ? .gray : .positive
                )
            }

            let shortcut = RecordedHotKey(
                name: .pauseResumeFlashSpace,
                hotKey: pauseResumeHotKey,
                action: action
            )
            addShortcut("General", shortcut)
        }

        // SpaceControl
        if let hotKey = SpaceControl.getHotKey() {
            addShortcut("Space Control", hotKey)
        }
    }

    func disableAll() {
        KeyboardShortcuts.removeAllHandlers()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        DistributedNotificationCenter.default()
            .publisher(for: .init(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String))
            .sink { [weak self] _ in
                KeyCodesMap.refresh()
                self?.refresh()
            }
            .store(in: &cancellables)

        settingsRepository.workspaceSettings.$isPaused
            .dropFirst()
            .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }
}
