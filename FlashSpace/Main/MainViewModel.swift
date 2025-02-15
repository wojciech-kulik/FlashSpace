//
//  MainViewModel.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var workspaceApps: [MacApp]?

    @Published var workspaceName = ""
    @Published var workspaceShortcut: AppHotKey? {
        didSet { saveWorkspace() }
    }

    @Published var workspaceAssignShortcut: AppHotKey? {
        didSet { saveWorkspace() }
    }

    @Published var workspaceDisplay = "" {
        didSet { saveWorkspace() }
    }

    @Published var workspaceAppToFocus: MacApp? = AppConstants.lastFocusedOption {
        didSet { saveWorkspace() }
    }

    @Published var workspaceSymbolIconName: String? {
        didSet { saveWorkspace() }
    }

    @Published var isSymbolPickerPresented = false
    @Published var isInputDialogPresented = false
    @Published var isWhatsNewPresented = false
    @Published var userInput = ""

    var focusAppOptions: [MacApp] {
        [AppConstants.lastFocusedOption] + (workspaceApps ?? [])
    }

    var selectedApp: MacApp? {
        didSet {
            guard selectedApp != oldValue else { return }

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.objectWillChange.send()
            }
        }
    }

    var selectedWorkspace: Workspace? {
        didSet {
            guard selectedWorkspace != oldValue else { return }

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.updateSelectedWorkspace()
            }
        }
    }

    var screens: [String] {
        let set = Set<String>(NSScreen.screens.compactMap(\.localizedName))
        let otherScreens = workspaces.map(\.display)
        return Array(set.union(otherScreens))
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var cancellables: Set<AnyCancellable> = []
    private var loadingWorkspace = false

    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let workspaceRepository = AppDependencies.shared.workspaceRepository

    init() {
        self.workspaces = workspaceRepository.workspaces
        self.workspaceDisplay = NSScreen.main?.localizedName ?? ""

        observe()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .appsListChanged)
            .sink { [weak self] _ in self?.reloadWorkspaces() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in self?.reloadWorkspaces() }
            .store(in: &cancellables)
    }

    private func updateSelectedWorkspace() {
        loadingWorkspace = true
        defer { loadingWorkspace = false }

        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.activateShortcut
        workspaceAssignShortcut = selectedWorkspace?.assignAppShortcut
        workspaceDisplay = selectedWorkspace?.display ?? NSScreen.main?.localizedName ?? ""
        workspaceApps = selectedWorkspace?.apps
        workspaceAppToFocus = selectedWorkspace?.appToFocus ?? AppConstants.lastFocusedOption
        workspaceSymbolIconName = selectedWorkspace?.symbolIconName
        selectedApp = workspaceApps?.first { $0 == selectedApp }
    }

    private func reloadWorkspaces() {
        workspaces = workspaceRepository.workspaces
        selectedWorkspace = workspaces.first { $0.id == selectedWorkspace?.id }
    }
}

extension MainViewModel {
    func saveWorkspace() {
        guard let selectedWorkspace, !loadingWorkspace else { return }

        if workspaceName.trimmingCharacters(in: .whitespaces).isEmpty {
            workspaceName = "(empty)"
        }

        let updatedWorkspace = Workspace(
            id: selectedWorkspace.id,
            name: workspaceName,
            display: workspaceDisplay,
            activateShortcut: workspaceShortcut,
            assignAppShortcut: workspaceAssignShortcut,
            apps: selectedWorkspace.apps,
            appToFocus: workspaceAppToFocus == AppConstants.lastFocusedOption ? nil : workspaceAppToFocus,
            symbolIconName: workspaceSymbolIconName
        )

        workspaceRepository.updateWorkspace(updatedWorkspace)
        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
    }

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

        let newIndex = min(workspaces.firstIndex { $0.id == selectedWorkspace.id } ?? 0, workspaces.count - 2)

        workspaceRepository.deleteWorkspace(id: selectedWorkspace.id)
        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces[safe: newIndex]
    }

    func addApp() {
        guard let selectedWorkspace else { return }

        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }

        let appName = appUrl.appName
        let appBundleId = appUrl.bundleIdentifier ?? ""
        let runningApp = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == appBundleId }
        let isAgent = appUrl.bundle?.isAgent == true && (runningApp == nil || runningApp?.activationPolicy != .regular)

        guard !isAgent else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashSpace."
            )
            return
        }

        guard !selectedWorkspace.apps.containsApp(with: appBundleId) else { return }

        workspaceRepository.addApp(
            to: selectedWorkspace.id,
            app: .init(
                name: appName,
                bundleIdentifier: appBundleId,
                iconPath: appUrl.iconPath
            )
        )

        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
    }

    func deleteApp() {
        guard let selectedWorkspace, let selectedApp else { return }

        let newAppIndex = min(workspaceApps?.firstIndex(of: selectedApp) ?? 0, (workspaceApps?.count ?? 1) - 2)

        workspaceRepository.deleteApp(
            from: selectedWorkspace.id,
            app: selectedApp
        )

        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaces.first { $0.id == selectedWorkspace.id }
        workspaceApps = self.selectedWorkspace?.apps
        self.selectedApp = workspaceApps?[safe: newAppIndex]
    }

    func resetWorkspaceSymbolIcon() {
        workspaceSymbolIconName = nil
        saveWorkspace()
    }

    func moveWorkspace(up: Bool) {
        guard let selectedWorkspace else { return }

        if up {
            workspaceRepository.moveUp(workspaceId: selectedWorkspace.id)
        } else {
            workspaceRepository.moveDown(workspaceId: selectedWorkspace.id)
        }

        workspaces = workspaceRepository.workspaces
    }

    func showWhatsNewIfNeeded() {
        @AppStorage("v1.1.17-whats-new") var whatsNewShown = false

        if workspaceRepository.workspaces.isEmpty {
            whatsNewShown = true
            return
        }

        guard !whatsNewShown else { return }

        whatsNewShown = true
        isWhatsNewPresented = true
    }
}
