//
//  MainViewModel.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import ShortcutRecorder
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var workspaceApps: [String]?

    @Published var workspaceName = ""
    @Published var workspaceShortcut: HotKeyShortcut?
    @Published var workspaceDisplay = ""

    @Published var selectedApp: String?
    @Published var selectedWorkspace: Workspace? {
        didSet {
            guard selectedWorkspace?.id != oldValue?.id else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateSelectedWorkspace()
            }
        }
    }

    @Published var isInputDialogPresented = false
    @Published var userInput = ""

    var isSaveButtonDisabled: Bool {
        guard let selectedWorkspace else { return true }
        guard !workspaceName.isEmpty, !workspaceDisplay.isEmpty else { return true }

        return selectedWorkspace.name == workspaceName &&
            selectedWorkspace.display == workspaceDisplay &&
            selectedWorkspace.shortcut == workspaceShortcut
    }

    private var cancellables: Set<AnyCancellable> = []

    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let hotKeysManager = AppDependencies.shared.hotKeysManager

    init() {
        self.workspaces = workspaceRepository.workspaces
        hotKeysManager.register(workspaces: workspaces)
        hotKeysManager.enableAll()
    }

    private func updateSelectedWorkspace() {
        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.shortcut
        workspaceDisplay = selectedWorkspace?.display ?? ""
        workspaceApps = selectedWorkspace?.apps
    }
}

extension MainViewModel {
    func addWorkspace() {
        userInput = ""
        isInputDialogPresented = true

        $isInputDialogPresented
            .first { !$0 }
            .sink { [weak self] _ in
                guard let self, !self.userInput.isEmpty else { return }

                self.workspaceRepository.addWorkspace(name: self.userInput)
                self.workspaces = self.workspaceRepository.workspaces
                self.selectedWorkspace = self.workspaces.last
            }
            .store(in: &cancellables)
    }

    func deleteWorkspace() {
        guard let selectedWorkspace else { return }

        workspaceRepository.deleteWorkspace(id: selectedWorkspace.id)
        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = nil
    }

    func updateWorkspace() {
        guard let selectedWorkspace else { return }

        let updatedWorkspace = Workspace(
            id: selectedWorkspace.id,
            name: workspaceName,
            display: workspaceDisplay,
            shortcut: workspaceShortcut,
            apps: selectedWorkspace.apps
        )

        if let workspaceShortcut {
            hotKeysManager.update(workspaceId: selectedWorkspace.id, shortcut: workspaceShortcut)
        }

        workspaceRepository.updateWorkspace(updatedWorkspace)
        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
    }

    func addApp() {
        guard let selectedWorkspace else { return }

        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }

        workspaceRepository.addApp(
            to: selectedWorkspace.id,
            app: appUrl.lastPathComponent.replacingOccurrences(of: ".app", with: "")
        )

        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
    }

    func deleteApp() {
        guard let selectedWorkspace, let selectedApp else { return }

        workspaceRepository.deleteApp(
            from: selectedWorkspace.id,
            app: selectedApp
        )

        workspaces = workspaceRepository.workspaces
        self.selectedApp = nil
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
    }
}

extension String {
    static let builtInDisplay = "Built-in Retina Display"
    static let dellDisplay = "DELL U2723QE"
}
