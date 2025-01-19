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
    @Published var workspaceShortcut: HotKeyShortcut?
    @Published var workspaceDisplay = ""
    @Published var workspaceApps: [String]?

    @Published var selectedApp: String?
    @Published var selectedWorkspace: Workspace? {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateSelectedWorkspace()
            }
        }
    }

    private let workspaceManager = WorkspaceManager()

    private func updateSelectedWorkspace() {
        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.shortcut
        workspaceDisplay = selectedWorkspace?.display ?? ""
        workspaceApps = selectedWorkspace?.apps
    }
}

extension String {
    static let builtInDisplay = "Built-in Retina Display"
    static let dellDisplay = "DELL U2723QE"
}
