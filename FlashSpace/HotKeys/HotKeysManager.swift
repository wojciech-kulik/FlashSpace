//
//  HotKeysManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder
import SwiftUI

struct HotKeyShortcut: Codable, Hashable {
    let keyCode: UInt16
    let modifiers: UInt
}

final class HotKeysManager {
    @Environment(\.openWindow) var openWindow

    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let workspaceManager: WorkspaceManager
    private let focusManager: FocusManager
    private let settingsRepository: SettingsRepository

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        workspaceManager: WorkspaceManager,
        focusManager: FocusManager,
        settingsRepository: SettingsRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.workspaceManager = workspaceManager
        self.focusManager = focusManager
        self.settingsRepository = settingsRepository
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    func enableAll() {
        for (shortcut, action) in workspaceManager.getHotKeys() {
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
            let action = ShortcutAction(shortcut: showHotKey) { [weak self] _ in
                self?.openWindow(id: "main")
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
}
