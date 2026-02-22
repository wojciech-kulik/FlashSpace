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
    @Published var workspaces: [Workspace] = [] {
        didSet {
            guard workspaces.count == oldValue.count,
                  workspaces.map(\.id) != oldValue.map(\.id) else { return }

            workspaceRepository.reorderWorkspaces(newOrder: workspaces.map(\.id))
        }
    }

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

    @Published var isOpenAppsOnActivationEnabled = false {
        didSet {
            if isOpenAppsOnActivationEnabled != oldValue, !loadingWorkspace, let selectedWorkspace {
                workspaceRepository.setAutoOpenForApps(isOpenAppsOnActivationEnabled, in: selectedWorkspace.id)
                updateApps()
            }

            if !isOpenAppsOnActivationEnabled {
                isEditingApps = false
            }

            saveWorkspace()
        }
    }

    @Published var isSymbolPickerPresented = false
    @Published var isInputDialogPresented = false
    @Published var isEditingApps = false
    @Published var userInput = ""

    var focusAppOptions: [MacApp] {
        [AppConstants.lastFocusedOption] + (workspaceApps ?? [])
    }

    var selectedApps: Set<MacApp> = [] {
        didSet {
            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                objectWillChange.send()
            }
        }
    }

    var selectedWorkspaces: Set<Workspace> = [] {
        didSet {
            selectedWorkspace = selectedWorkspaces.count == 1
                ? selectedWorkspaces.first
                : nil

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                if selectedWorkspaces.count == 1,
                   selectedWorkspaces.first?.id != oldValue.first?.id {
                    selectedApps = []
                } else if selectedWorkspaces.count != 1 {
                    selectedApps = []
                }
                objectWillChange.send()
            }
        }
    }

    private(set) var selectedWorkspace: Workspace? {
        didSet {
            guard selectedWorkspace != oldValue else { return }

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.updateSelectedWorkspace()
            }
        }
    }

    var screens: [String] {
        let set = NSScreen.screens.compactMap(\.localizedName).asSet
        let otherScreens = workspaces.map(\.display)

        return Array(set.union(otherScreens))
            .filter(\.isNotEmpty)
            .sorted()
    }

    var displayMode: DisplayMode { workspaceSettings.displayMode }

    private var cancellables: Set<AnyCancellable> = []
    private var loadingWorkspace = false

    private let workspaceManager = AppDependencies.shared.workspaceManager
    private let workspaceRepository = AppDependencies.shared.workspaceRepository
    private let workspaceSettings = AppDependencies.shared.workspaceSettings

    init() {
        self.workspaces = workspaceRepository.workspaces
        self.workspaceDisplay = .current

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

        workspaceSettings.updatePublisher
            .compactMap { [weak self] in self?.workspaceSettings.displayMode }
            .removeDuplicates()
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func updateSelectedWorkspace() {
        loadingWorkspace = true
        defer { loadingWorkspace = false }

        workspaceName = selectedWorkspace?.name ?? ""
        workspaceShortcut = selectedWorkspace?.activateShortcut
        workspaceAssignShortcut = selectedWorkspace?.assignAppShortcut
        workspaceDisplay = selectedWorkspace?.display ?? .current
        workspaceAppToFocus = selectedWorkspace?.appToFocus ?? AppConstants.lastFocusedOption
        workspaceSymbolIconName = selectedWorkspace?.symbolIconName
        isOpenAppsOnActivationEnabled = selectedWorkspace?.openAppsOnActivation ?? false
        selectedWorkspace.flatMap { selectedWorkspaces = [$0] }
        isEditingApps = false

        updateApps()
    }

    private func updateApps() {
        if let selectedWorkspace {
            workspaceApps = workspaceRepository.findWorkspace(with: selectedWorkspace.id)?.apps
        } else {
            workspaceApps = nil
        }
    }

    private func reloadWorkspaces() {
        workspaces = workspaceRepository.workspaces
        if let selectedWorkspace, let workspace = workspaceRepository.findWorkspace(with: selectedWorkspace.id) {
            selectedWorkspaces = [workspace]
        } else {
            selectedWorkspaces = []
        }
        selectedApps = []
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
            apps: workspaceApps ?? [],
            appToFocus: workspaceAppToFocus == AppConstants.lastFocusedOption ? nil : workspaceAppToFocus,
            symbolIconName: workspaceSymbolIconName,
            openAppsOnActivation: isOpenAppsOnActivationEnabled
        )

        workspaceRepository.updateWorkspace(updatedWorkspace)
        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaceRepository.findWorkspace(with: selectedWorkspace.id)
        self.selectedWorkspace.flatMap { selectedWorkspaces = [$0] }
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
                self.selectedWorkspace.flatMap { self.selectedWorkspaces = [$0] }
            }
            .store(in: &cancellables)
    }

    func duplicateWorkspaces(_ duplicates: Set<Workspace>) {
        let newWorkspaces = duplicates.map { duplicate in
            var newWorkspace = duplicate
            newWorkspace.id = .init()
            newWorkspace.activateShortcut = nil
            newWorkspace.assignAppShortcut = nil
            return newWorkspace
        }
        workspaceRepository.addWorkspaces(contentsOf: newWorkspaces)
        workspaces = workspaceRepository.workspaces
        selectedWorkspaces = Set(newWorkspaces)
    }

    func deleteSelectedWorkspaces() {
        guard !selectedWorkspaces.isEmpty else { return }

        workspaceRepository.deleteWorkspaces(ids: selectedWorkspaces.map(\.id).asSet)
        workspaces = workspaceRepository.workspaces
        selectedWorkspaces = []
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

        guard !(workspaceApps ?? []).containsApp(with: appBundleId) else { return }

        workspaceRepository.addApp(
            to: selectedWorkspace.id,
            app: .init(
                name: appName,
                bundleIdentifier: appBundleId,
                iconPath: appUrl.iconPath,
                autoOpen: isOpenAppsOnActivationEnabled ? true : nil
            )
        )

        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaceRepository.findWorkspace(with: selectedWorkspace.id)
        self.selectedWorkspace.flatMap { selectedWorkspaces = [$0] }

        workspaceManager.activateWorkspaceIfActive(selectedWorkspace.id)
    }

    func deleteSelectedApps() {
        guard let selectedWorkspace, !selectedApps.isEmpty else { return }

        let selectedApps = Array(selectedApps)

        for app in selectedApps {
            workspaceRepository.deleteApp(
                from: selectedWorkspace.id,
                app: app,
                notify: app == selectedApps.last
            )
        }

        workspaces = workspaceRepository.workspaces
        self.selectedWorkspace = workspaceRepository.findWorkspace(with: selectedWorkspace.id)
        workspaceApps = self.selectedWorkspace?.apps
        self.selectedApps = []

        workspaceManager.activateWorkspaceIfActive(selectedWorkspace.id)
    }

    func setAutoOpen(_ enabled: Bool, for app: MacApp, in workspaceId: WorkspaceID) {
        workspaceRepository.setAutoOpen(enabled, for: app, in: workspaceId)
        updateApps()
    }

    func isAutoOpenEnabled(for app: MacApp) -> Bool {
        guard let refreshedApp = workspaceApps?.first(where: { $0 == app }) else {
            return false
        }
        return refreshedApp.autoOpen ?? false
    }

    func resetWorkspaceSymbolIcon() {
        workspaceSymbolIconName = nil
        saveWorkspace()
    }
}
