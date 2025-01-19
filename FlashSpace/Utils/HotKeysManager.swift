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
        disableAll()
        enableAll()
        print("Updated shortcut for workspace: \(workspaceId)")
    }

    func enableAll() {
        for (workspaceID, hotKey) in registeredHotKeys {
            guard let shortcut = shortcut(for: hotKey) else {
                print("Could not create shortcut for workspace: \(workspaceID)")
                continue
            }

            let action = ShortcutAction(shortcut: shortcut) { _ in
                let workspaces = AppDependencies.shared.workspaceRepository.workspaces
                guard let workspace = workspaces.first(where: { $0.id == workspaceID }) else { return false }

                AppDependencies.shared.workspaceManager.activateWorkspace(workspace)
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

    private func shortcut(for hotKey: HotKeyShortcut) -> Shortcut? {
        guard let keyCode = KeyCode(rawValue: hotKey.keyCode) else { return nil }

        return Shortcut(code: keyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: hotKey.modifiers))
    }
}
