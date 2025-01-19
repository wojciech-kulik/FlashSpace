//
//  MainViewModel.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var workspaceName = ""
    @Published var workspaceShortcut = ""
    @Published var workspaceDisplay = ""
    @Published var workspaceApps: [String]?
    @Published var selectedWorkspace: Workspace? {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateSelectedWorkspace()
            }
        }
    }

    private let hotKeysMonitor = GlobalShortcutMonitor()
    private let workspaceManager = WorkspaceManager()

    init() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        self.workspaces = [
            Workspace(
                id: UUID(),
                name: "1",
                display: .dellDisplay,
                shortcut: "ALT + 1",
                apps: ["Arc"]
            ),
            Workspace(
                id: UUID(),
                name: "2",
                display: .dellDisplay,
                shortcut: "ALT + 2",
                apps: ["kitty", "Simulator"]
            ),
            Workspace(
                id: UUID(),
                name: "3",
                display: .dellDisplay,
                shortcut: "ALT + 3",
                apps: ["Xcode"]
            ),
            Workspace(
                id: UUID(),
                name: "6",
                display: .builtInDisplay,
                shortcut: "ALT + 6",
                apps: ["Slack"]
            ),
            Workspace(
                id: UUID(),
                name: "7",
                display: .builtInDisplay,
                shortcut: "ALT + 7",
                apps: ["Messages", "Signal"]
            ),
            Workspace(
                id: UUID(),
                name: "8",
                display: .builtInDisplay,
                shortcut: "ALT + 8",
                apps: ["Spotify"]
            )
        ]

        registerHotKeys()
    }

    private func registerHotKeys() {
        for workspace in workspaces {
            let keyCode: KeyCode = switch workspace.name {
            case "1": .ansi1
            case "2": .ansi2
            case "3": .ansi3
            case "4": .ansi4
            case "5": .ansi5
            case "6": .ansi6
            case "7": .ansi7
            case "8": .ansi8
            default: .ansi9
            }

            let action = ShortcutAction(shortcut: .init(code: keyCode, modifierFlags: [.option])) { [weak self] _ in
                self?.workspaceManager.showWorkspace(workspace)
                return true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }
    }

    private func updateSelectedWorkspace() {
        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.shortcut ?? ""
        workspaceDisplay = selectedWorkspace?.display ?? ""
        workspaceApps = selectedWorkspace?.apps
    }
}

extension String {
    static let builtInDisplay = "Built-in Retina Display"
    static let dellDisplay = "DELL U2723QE"
}
