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
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    @Published var workspaces: [Workspace] = []
    @Published var workspaceApps: [String]?

    @Published var workspaceName = ""
    @Published var workspaceShortcut: HotKeyShortcut?
    @Published var workspaceAssignShortcut: HotKeyShortcut?
    @Published var workspaceDisplay = ""

    @Published var selectedApp: String?
    @Published var selectedWorkspace: Workspace? {
        didSet {
            guard selectedWorkspace != oldValue else { return }

            updatingWorkspace = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updatingWorkspace = false
                self.updateSelectedWorkspace()
            }
        }
    }

    @Published var isAutostartEnabled: Bool {
        didSet {
            guard isAutostartEnabled != oldValue else { return }

            if isAutostartEnabled {
                autostartService.enableLaunchAtLogin()
            } else {
                autostartService.disableLaunchAtLogin()
            }
        }
    }

    @Published var isInputDialogPresented = false
    @Published var userInput = ""

    var screens: [String] {
        let set = Set<String>(NSScreen.screens.compactMap(\.localizedName))
        let otherScreens = workspaces.map(\.display)
        return Array(set.union(otherScreens))
            .filter { !$0.isEmpty }
            .sorted()
    }

    var isSaveButtonDisabled: Bool {
        guard let selectedWorkspace, !updatingWorkspace else { return true }
        guard !workspaceName.isEmpty, !workspaceDisplay.isEmpty else { return true }

        return selectedWorkspace.name == workspaceName &&
            selectedWorkspace.display == workspaceDisplay &&
            selectedWorkspace.activateShortcut == workspaceShortcut &&
            selectedWorkspace.assignAppShortcut == workspaceAssignShortcut
    }

    private var cancellables: Set<AnyCancellable> = []
    private var updatingWorkspace = false

    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let hotKeysManager = AppDependencies.shared.hotKeysManager
    private let autostartService = AppDependencies.shared.autostartService

    init() {
        self.workspaces = workspaceRepository.workspaces
        self.isAutostartEnabled = autostartService.isLaunchAtLoginEnabled
        self.workspaceDisplay = NSScreen.main?.localizedName ?? ""

        hotKeysManager.enableAll()
        dismissIfNotFirstTime()
        observe()
    }

    private func dismissIfNotFirstTime() {
        if UserDefaults.standard.object(forKey: "afterFirstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "afterFirstLaunch")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dismissWindow(id: "main")
            }
        }
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .newAppAssigned)
            .sink { [weak self] _ in self?.reloadWorkspaces() }
            .store(in: &cancellables)
    }

    private func updateSelectedWorkspace() {
        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.activateShortcut
        workspaceAssignShortcut = selectedWorkspace?.assignAppShortcut
        workspaceDisplay = selectedWorkspace?.display ?? NSScreen.main?.localizedName ?? ""
        workspaceApps = selectedWorkspace?.apps
        selectedApp = nil
    }

    private func reloadWorkspaces() {
        workspaces = workspaceRepository.workspaces
        selectedWorkspace = workspaces.first { $0.id == selectedWorkspace?.id }
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
            activateShortcut: workspaceShortcut,
            assignAppShortcut: workspaceAssignShortcut,
            apps: selectedWorkspace.apps
        )

        workspaceRepository.updateWorkspace(updatedWorkspace)
        hotKeysManager.refresh()
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

        let appName = appUrl.lastPathComponent.replacingOccurrences(of: ".app", with: "")

        guard !selectedWorkspace.apps.contains(appName) else { return }

        workspaceRepository.addApp(
            to: selectedWorkspace.id,
            app: appName
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
