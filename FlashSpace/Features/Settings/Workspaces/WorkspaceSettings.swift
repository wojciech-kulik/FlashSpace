//
//  WorkspaceSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class WorkspaceSettings: ObservableObject {
    @Published var displayMode: DisplayMode = .static

    @Published var centerCursorOnWorkspaceChange = false
    @Published var changeWorkspaceOnAppAssign = true
    @Published var activeWorkspaceOnFocusChange = true
    @Published var skipEmptyWorkspacesOnSwitch = false
    @Published var keepUnassignedAppsOnSwitch = false
    @Published var restoreHiddenAppsOnSwitch = true
    @Published var enableWorkspaceTransitions = false
    @Published var workspaceTransitionDuration = 0.3
    @Published var workspaceTransitionDimming = 0.2

    @Published var assignFocusedApp: AppHotKey?
    @Published var unassignFocusedApp: AppHotKey?
    @Published var toggleFocusedAppAssignment: AppHotKey?
    @Published var assignVisibleApps: AppHotKey?
    @Published var hideUnassignedApps: AppHotKey?

    @Published var loopWorkspaces = true
    @Published var switchToRecentWorkspace: AppHotKey?
    @Published var switchToPreviousWorkspace: AppHotKey?
    @Published var switchToNextWorkspace: AppHotKey?

    @Published var alternativeDisplays = ""

    @Published var enablePictureInPictureSupport = true
    @Published var switchWorkspaceWhenPipCloses = true
    @Published var pipScreenCornerOffset = 15
    @Published var pipApps: [PipApp] = []

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    func addPipApp(_ app: PipApp) {
        pipApps.append(app)
    }

    func deletePipApp(_ app: PipApp) {
        pipApps.removeAll { $0 == app }
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $displayMode.settingsPublisher(),

            $centerCursorOnWorkspaceChange.settingsPublisher(),
            $changeWorkspaceOnAppAssign.settingsPublisher(),
            $activeWorkspaceOnFocusChange.settingsPublisher(),
            $skipEmptyWorkspacesOnSwitch.settingsPublisher(),
            $keepUnassignedAppsOnSwitch.settingsPublisher(),
            $restoreHiddenAppsOnSwitch.settingsPublisher(),
            $enableWorkspaceTransitions.settingsPublisher(),
            $workspaceTransitionDuration.settingsPublisher(debounce: true),
            $workspaceTransitionDimming.settingsPublisher(debounce: true),

            $assignFocusedApp.settingsPublisher(),
            $unassignFocusedApp.settingsPublisher(),
            $toggleFocusedAppAssignment.settingsPublisher(),
            $assignVisibleApps.settingsPublisher(),
            $hideUnassignedApps.settingsPublisher(),

            $loopWorkspaces.settingsPublisher(),
            $switchToRecentWorkspace.settingsPublisher(),
            $switchToPreviousWorkspace.settingsPublisher(),
            $switchToNextWorkspace.settingsPublisher(),

            $alternativeDisplays.settingsPublisher(debounce: true),
            $enablePictureInPictureSupport.settingsPublisher(),
            $switchWorkspaceWhenPipCloses.settingsPublisher(),
            $pipApps.settingsPublisher(),
            $pipScreenCornerOffset.settingsPublisher(debounce: true)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension WorkspaceSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        displayMode = appSettings.displayMode ?? .static

        centerCursorOnWorkspaceChange = appSettings.centerCursorOnWorkspaceChange ?? false
        changeWorkspaceOnAppAssign = appSettings.changeWorkspaceOnAppAssign ?? true
        activeWorkspaceOnFocusChange = appSettings.activeWorkspaceOnFocusChange ?? true
        skipEmptyWorkspacesOnSwitch = appSettings.skipEmptyWorkspacesOnSwitch ?? false
        keepUnassignedAppsOnSwitch = appSettings.keepUnassignedAppsOnSwitch ?? false
        restoreHiddenAppsOnSwitch = appSettings.restoreHiddenAppsOnSwitch ?? true
        enableWorkspaceTransitions = appSettings.enableWorkspaceTransitions ?? false
        workspaceTransitionDuration = min(appSettings.workspaceTransitionDuration ?? 0.3, 0.5)
        workspaceTransitionDimming = min(appSettings.workspaceTransitionDimming ?? 0.2, 0.5)

        assignFocusedApp = appSettings.assignFocusedApp
        unassignFocusedApp = appSettings.unassignFocusedApp
        toggleFocusedAppAssignment = appSettings.toggleFocusedAppAssignment
        assignVisibleApps = appSettings.assignVisibleApps
        hideUnassignedApps = appSettings.hideUnassignedApps

        loopWorkspaces = appSettings.loopWorkspaces ?? true
        switchToRecentWorkspace = appSettings.switchToRecentWorkspace
        switchToPreviousWorkspace = appSettings.switchToPreviousWorkspace
        switchToNextWorkspace = appSettings.switchToNextWorkspace

        alternativeDisplays = appSettings.alternativeDisplays ?? ""
        enablePictureInPictureSupport = appSettings.enablePictureInPictureSupport ?? true
        switchWorkspaceWhenPipCloses = appSettings.switchWorkspaceWhenPipCloses ?? true
        pipApps = appSettings.pipApps ?? []
        pipScreenCornerOffset = appSettings.pipScreenCornerOffset ?? 15
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.displayMode = displayMode

        appSettings.centerCursorOnWorkspaceChange = centerCursorOnWorkspaceChange
        appSettings.changeWorkspaceOnAppAssign = changeWorkspaceOnAppAssign
        appSettings.activeWorkspaceOnFocusChange = activeWorkspaceOnFocusChange
        appSettings.skipEmptyWorkspacesOnSwitch = skipEmptyWorkspacesOnSwitch
        appSettings.keepUnassignedAppsOnSwitch = keepUnassignedAppsOnSwitch
        appSettings.restoreHiddenAppsOnSwitch = restoreHiddenAppsOnSwitch
        appSettings.enableWorkspaceTransitions = enableWorkspaceTransitions
        appSettings.workspaceTransitionDuration = workspaceTransitionDuration
        appSettings.workspaceTransitionDimming = workspaceTransitionDimming

        appSettings.assignFocusedApp = assignFocusedApp
        appSettings.unassignFocusedApp = unassignFocusedApp
        appSettings.toggleFocusedAppAssignment = toggleFocusedAppAssignment
        appSettings.assignVisibleApps = assignVisibleApps
        appSettings.hideUnassignedApps = hideUnassignedApps

        appSettings.loopWorkspaces = loopWorkspaces
        appSettings.switchToRecentWorkspace = switchToRecentWorkspace
        appSettings.switchToPreviousWorkspace = switchToPreviousWorkspace
        appSettings.switchToNextWorkspace = switchToNextWorkspace

        appSettings.alternativeDisplays = alternativeDisplays
        appSettings.enablePictureInPictureSupport = enablePictureInPictureSupport
        appSettings.switchWorkspaceWhenPipCloses = switchWorkspaceWhenPipCloses
        appSettings.pipApps = pipApps
        appSettings.pipScreenCornerOffset = pipScreenCornerOffset
    }
}
