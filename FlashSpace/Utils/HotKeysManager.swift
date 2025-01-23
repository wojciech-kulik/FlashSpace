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
    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let workspaceRepository: WorkspaceRepository
    private let workspaceManager: WorkspaceManager

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        workspaceRepository: WorkspaceRepository,
        workspaceManager: WorkspaceManager
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.workspaceRepository = workspaceRepository
        self.workspaceManager = workspaceManager
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    func enableAll() {
        for workspace in workspaceRepository.workspaces {
            setActivateShortcut(for: workspace)
            setAssignShortcut(for: workspace)
        }
        print("Enabled all shortcuts")
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
        print("Disabled all shortcuts")
    }

    private func setActivateShortcut(for workspace: Workspace) {
        guard let activateShortcut = workspace.activateShortcut else { return }
        guard let shortcut = shortcut(for: activateShortcut) else {
            return print("Could not create activate shortcut for workspace: \(workspace.id)")
        }

        let action = ShortcutAction(shortcut: shortcut) { [weak self] _ in
            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return true }

            self?.workspaceManager.activateWorkspace(updatedWorkspace, setFocus: true)
            return true
        }

        hotKeysMonitor.addAction(action, forKeyEvent: .down)
    }

    private func setAssignShortcut(for workspace: Workspace) {
        guard let assignShortcut = workspace.assignAppShortcut else { return }
        guard let shortcut = shortcut(for: assignShortcut) else {
            return print("Could not create assign app shortcut for workspace: \(workspace.id)")
        }

        let action = ShortcutAction(shortcut: shortcut) { [weak self] _ in
            guard let activeApp = NSWorkspace.shared.frontmostApplication,
                  let activeAppName = activeApp.localizedName else { return true }

            activeApp.centerApp(display: workspace.display)
            self?.workspaceRepository.deleteAppFromAllWorkspaces(app: activeAppName)
            self?.workspaceRepository.addApp(to: workspace.id, app: activeAppName)

            guard let updatedWorkspace = self?.workspaceRepository.workspaces
                .first(where: { $0.id == workspace.id }) else { return true }

            self?.workspaceManager.activateWorkspace(updatedWorkspace, setFocus: false)
            NotificationCenter.default.post(name: .newAppAssigned, object: nil)
            return true
        }

        hotKeysMonitor.addAction(action, forKeyEvent: .down)
    }

    private func shortcut(for hotKey: HotKeyShortcut) -> Shortcut? {
        guard let keyCode = KeyCode(rawValue: hotKey.keyCode) else { return nil }

        return Shortcut(code: keyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: hotKey.modifiers))
    }
}
