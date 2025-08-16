//
//  HotKeysManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import ShortcutRecorder

final class HotKeysManager {
    private(set) var allHotKeys: [(scope: String, hotKey: AppHotKey)] = []

    private var cancellables = Set<AnyCancellable>()

    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let workspaceHotKeys: WorkspaceHotKeys
    private let floatingAppsHotKeys: FloatingAppsHotKeys
    private let focusManager: FocusManager
    private let settingsRepository: SettingsRepository
    private let profilesRepository: ProfilesRepository

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        workspaceHotKeys: WorkspaceHotKeys,
        floatingAppsHotKeys: FloatingAppsHotKeys,
        focusManager: FocusManager,
        settingsRepository: SettingsRepository,
        profilesRepository: ProfilesRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.workspaceHotKeys = workspaceHotKeys
        self.floatingAppsHotKeys = floatingAppsHotKeys
        self.focusManager = focusManager
        self.settingsRepository = settingsRepository
        self.profilesRepository = profilesRepository

        observe()
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    // swiftlint:disable:next function_body_length
    func enableAll() {
        allHotKeys.removeAll()
        let addShortcut = { (title: String, shortcut: Shortcut) in
            self.allHotKeys.append((title, .init(
                keyCode: shortcut.keyCode.rawValue,
                modifiers: shortcut.modifierFlags.rawValue
            )))
        }

        // Workspaces
        for (shortcut, action) in workspaceHotKeys.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("Workspace", shortcut)
        }

        // Profiles
        for (shortcut, action) in profilesRepository.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("Profile", shortcut)
        }

        // Floating Apps
        for (shortcut, action) in floatingAppsHotKeys.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("Floating Apps", shortcut)
        }

        // Focus Manager
        for (shortcut, action) in focusManager.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("Focus Manager", shortcut)
        }

        // General
        if let showHotKey = settingsRepository.generalSettings.showFlashSpace?.toShortcut() {
            let action = ShortcutAction(shortcut: showHotKey) { _ in
                guard !SpaceControl.isVisible else { return true }

                let visibleAppWindows = NSApp.windows
                    .filter(\.isVisible)
                    .filter { $0.identifier?.rawValue == "main" || $0.identifier?.rawValue == "settings" }

                if visibleAppWindows.isEmpty {
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
                } else {
                    visibleAppWindows.forEach { $0.close() }
                }
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("General", showHotKey)
        }

        // SpaceControl
        if let (hotKey, action) = SpaceControl.getHotKey(), let shortcut = hotKey.toShortcut() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("Space Control", shortcut)
        }
        Logger.log("Enabling all hotkeys...")
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
        Logger.log("Disabling all hotkeys...")
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
                self?.disableAll()
                self?.enableAll()
            }
            .store(in: &cancellables)
    }
}
