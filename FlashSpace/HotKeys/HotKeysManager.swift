//
//  HotKeysManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import ShortcutRecorder

struct HotKeyShortcut: Codable, Hashable {
    let keyCode: UInt16
    let modifiers: UInt
}

final class HotKeysManager {
    private var cancellables = Set<AnyCancellable>()

    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let workspaceHotKeys: WorkspaceHotKeys
    private let focusManager: FocusManager
    private let settingsRepository: SettingsRepository

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        workspaceHotKeys: WorkspaceHotKeys,
        focusManager: FocusManager,
        settingsRepository: SettingsRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.workspaceHotKeys = workspaceHotKeys
        self.focusManager = focusManager
        self.settingsRepository = settingsRepository

        observe()
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    func enableAll() {
        for (shortcut, action) in workspaceHotKeys.getHotKeys() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }

        for (shortcut, action) in focusManager.getHotKeys() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }

        if let showHotKey = settingsRepository.showFlashSpace?.toShortcut() {
            let action = ShortcutAction(shortcut: showHotKey) { _ in
                NotificationCenter.default.post(name: .openMainWindow, object: nil)
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }

        print("Enabled all shortcuts")
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
        print("Disabled all shortcuts")
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }
}
