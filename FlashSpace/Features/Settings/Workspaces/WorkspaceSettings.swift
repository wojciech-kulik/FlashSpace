//
//  WorkspaceSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class WorkspaceSettings: ObservableObject {
    @Published var centerCursorOnWorkspaceChange = false
    @Published var changeWorkspaceOnAppAssign = true
    @Published var enablePictureInPictureSupport = true
    @Published var enableWorkspaceTransitions = false
    @Published var workspaceTransitionDuration = 0.3
    @Published var workspaceTransitionDimming = 0.2

    @Published var assignFocusedApp: AppHotKey?
    @Published var unassignFocusedApp: AppHotKey?
    @Published var toggleFocusedAppAssignment: AppHotKey?
    @Published var switchToRecentWorkspace: AppHotKey?
    @Published var switchToPreviousWorkspace: AppHotKey?
    @Published var switchToNextWorkspace: AppHotKey?
    @Published var skipEmptyWorkspacesOnSwitch = false

    @Published var alternativeDisplays = ""
    @Published var pipApps: [PipApp] = []
    @Published var pipScreenCornerOffset = 15

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
            $centerCursorOnWorkspaceChange.settingsPublisher(),
            $changeWorkspaceOnAppAssign.settingsPublisher(),
            $enablePictureInPictureSupport.settingsPublisher(),
            $assignFocusedApp.settingsPublisher(),
            $unassignFocusedApp.settingsPublisher(),
            $toggleFocusedAppAssignment.settingsPublisher(),
            $switchToRecentWorkspace.settingsPublisher(),
            $switchToPreviousWorkspace.settingsPublisher(),
            $switchToNextWorkspace.settingsPublisher(),
            $skipEmptyWorkspacesOnSwitch.settingsPublisher(),
            $alternativeDisplays.settingsPublisher(debounce: true),
            $pipApps.settingsPublisher(),
            $pipScreenCornerOffset.settingsPublisher(debounce: true),
            $enableWorkspaceTransitions.settingsPublisher(),
            $workspaceTransitionDuration.settingsPublisher(debounce: true),
            $workspaceTransitionDimming.settingsPublisher(debounce: true)
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
        centerCursorOnWorkspaceChange = appSettings.centerCursorOnWorkspaceChange ?? false
        changeWorkspaceOnAppAssign = appSettings.changeWorkspaceOnAppAssign ?? true
        enablePictureInPictureSupport = appSettings.enablePictureInPictureSupport ?? true
        enableWorkspaceTransitions = appSettings.enableWorkspaceTransitions ?? false
        workspaceTransitionDuration = min(appSettings.workspaceTransitionDuration ?? 0.3, 0.5)
        workspaceTransitionDimming = min(appSettings.workspaceTransitionDimming ?? 0.2, 0.5)

        assignFocusedApp = appSettings.assignFocusedApp
        unassignFocusedApp = appSettings.unassignFocusedApp
        toggleFocusedAppAssignment = appSettings.toggleFocusedAppAssignment
        switchToRecentWorkspace = appSettings.switchToRecentWorkspace
        switchToPreviousWorkspace = appSettings.switchToPreviousWorkspace
        switchToNextWorkspace = appSettings.switchToNextWorkspace
        skipEmptyWorkspacesOnSwitch = appSettings.skipEmptyWorkspacesOnSwitch ?? false

        alternativeDisplays = appSettings.alternativeDisplays ?? ""
        pipApps = appSettings.pipApps ?? []
        pipScreenCornerOffset = appSettings.pipScreenCornerOffset ?? 15
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.centerCursorOnWorkspaceChange = centerCursorOnWorkspaceChange
        appSettings.changeWorkspaceOnAppAssign = changeWorkspaceOnAppAssign
        appSettings.enablePictureInPictureSupport = enablePictureInPictureSupport
        appSettings.enableWorkspaceTransitions = enableWorkspaceTransitions
        appSettings.workspaceTransitionDuration = workspaceTransitionDuration
        appSettings.workspaceTransitionDimming = workspaceTransitionDimming

        appSettings.assignFocusedApp = assignFocusedApp
        appSettings.unassignFocusedApp = unassignFocusedApp
        appSettings.toggleFocusedAppAssignment = toggleFocusedAppAssignment
        appSettings.switchToRecentWorkspace = switchToRecentWorkspace
        appSettings.switchToPreviousWorkspace = switchToPreviousWorkspace
        appSettings.switchToNextWorkspace = switchToNextWorkspace
        appSettings.skipEmptyWorkspacesOnSwitch = skipEmptyWorkspacesOnSwitch

        appSettings.alternativeDisplays = alternativeDisplays
        appSettings.pipApps = pipApps
        appSettings.pipScreenCornerOffset = pipScreenCornerOffset
    }
}
