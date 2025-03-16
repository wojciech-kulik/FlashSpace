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

    @Published var assignFocusedApp: AppHotKey?
    @Published var unassignFocusedApp: AppHotKey?
    @Published var toggleFocusedAppAssignment: AppHotKey?
    @Published var switchToRecentWorkspace: AppHotKey?
    @Published var switchToPreviousWorkspace: AppHotKey?
    @Published var switchToNextWorkspace: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

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
            $switchToNextWorkspace.settingsPublisher()
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

        assignFocusedApp = appSettings.assignFocusedApp
        unassignFocusedApp = appSettings.unassignFocusedApp
        toggleFocusedAppAssignment = appSettings.toggleFocusedAppAssignment
        switchToRecentWorkspace = appSettings.switchToRecentWorkspace
        switchToPreviousWorkspace = appSettings.switchToPreviousWorkspace
        switchToNextWorkspace = appSettings.switchToNextWorkspace
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.centerCursorOnWorkspaceChange = centerCursorOnWorkspaceChange
        appSettings.changeWorkspaceOnAppAssign = changeWorkspaceOnAppAssign
        appSettings.enablePictureInPictureSupport = enablePictureInPictureSupport

        appSettings.assignFocusedApp = assignFocusedApp
        appSettings.unassignFocusedApp = unassignFocusedApp
        appSettings.toggleFocusedAppAssignment = toggleFocusedAppAssignment
        appSettings.switchToRecentWorkspace = switchToRecentWorkspace
        appSettings.switchToPreviousWorkspace = switchToPreviousWorkspace
        appSettings.switchToNextWorkspace = switchToNextWorkspace
    }
}
