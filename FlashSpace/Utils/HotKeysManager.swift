//
//  HotKeysManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder

struct HotKeyShortcut: Codable, Hashable {
    let keyCode: UInt16
    let modifiers: UInt
}

final class HotKeysManager {
    private var registeredHotKeys: [WorkspaceID: HotKeyShortcut] = [:]

    private let hotKeysMonitor: HotKeysMonitorProtocol

    init(hotKeysMonitor: HotKeysMonitorProtocol) {
        self.hotKeysMonitor = hotKeysMonitor
    }

    func register(workspaces: [Workspace]) {
        for workspace in workspaces {
            registeredHotKeys[workspace.id] = workspace.shortcut
        }
    }

    func update(workspaceId: WorkspaceID, shortcut: HotKeyShortcut) {
        registeredHotKeys[workspaceId] = shortcut
    }

    func enableAll() {
        for (workspaceID, hotKey) in registeredHotKeys {
            guard let shortcut = shortcut(for: hotKey) else {
                print("Could not create shortcut for workspace: \(workspaceID)")
                continue
            }

            let action = ShortcutAction(shortcut: shortcut) { [weak self] _ in
                true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
    }

    private func shortcut(for hotKey: HotKeyShortcut) -> Shortcut? {
        guard let keyCode = KeyCode(rawValue: hotKey.keyCode) else { return nil }

        return Shortcut(code: keyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: hotKey.modifiers))
    }
}
