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

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        workspaceHotKeys: WorkspaceHotKeys,
        floatingAppsHotKeys: FloatingAppsHotKeys,
        focusManager: FocusManager,
        settingsRepository: SettingsRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.workspaceHotKeys = workspaceHotKeys
        self.floatingAppsHotKeys = floatingAppsHotKeys
        self.focusManager = focusManager
        self.settingsRepository = settingsRepository

        observe()
    }

    func refresh() {
        disableAll()
        enableAll()
    }

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

                if NSApp.windows.contains(where: \.isVisible) {
                    NSApp.windows
                        .filter(\.isVisible)
                        .forEach { $0.close() }
                } else {
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
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
            addShortcut("SpaceControl", shortcut)
        }
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }
}
