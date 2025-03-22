//
//  WorkspaceSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class WorkspaceSettings: ObservableObject {
    enum FingerCount: Int, CaseIterable, Identifiable {
        case three = 3
        case four = 4

        var id: Int { rawValue }

        var description: String {
            switch self {
            case .three: return "Three Fingers"
            case .four: return "Four Fingers"
            }
        }
    }

    // General workspace settings
    @Published var centerCursorOnWorkspaceChange = false
    @Published var changeWorkspaceOnAppAssign = true
    @Published var enablePictureInPictureSupport = true
    @Published var enableWorkspaceTransition = true

    // Hotkeys
    @Published var assignFocusedApp: AppHotKey?
    @Published var unassignFocusedApp: AppHotKey?
    @Published var toggleFocusedAppAssignment: AppHotKey?
    @Published var switchToRecentWorkspace: AppHotKey?
    @Published var switchToPreviousWorkspace: AppHotKey?
    @Published var switchToNextWorkspace: AppHotKey?

    // Swipe gesture settings
    @Published var enableSwipeGesture = false {
        didSet { updateSwipeManager() }
    }

    @Published var swipeFingerCount: FingerCount = .three {
        didSet { updateSwipeManager() }
    }

    @Published var naturalDirection = false
    @Published var swipeThreshold: Double = 0.3

    @Published var alternativeDisplays = ""
    
    private func updateSwipeManager() {
        if enableSwipeGesture {
            SwipeManager.shared.start()
        } else {
            SwipeManager.shared.stop()
        }
    }

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            // General workspace settings
            $centerCursorOnWorkspaceChange.settingsPublisher(),
            $changeWorkspaceOnAppAssign.settingsPublisher(),
            $enablePictureInPictureSupport.settingsPublisher(),
            $enableWorkspaceTransition.settingsPublisher(),

            // Hotkeys
            $assignFocusedApp.settingsPublisher(),
            $unassignFocusedApp.settingsPublisher(),
            $toggleFocusedAppAssignment.settingsPublisher(),
            $switchToRecentWorkspace.settingsPublisher(),
            $switchToPreviousWorkspace.settingsPublisher(),
            $switchToNextWorkspace.settingsPublisher(),

            // Swipe settings
            $enableSwipeGesture.settingsPublisher(),
            $swipeFingerCount.settingsPublisher(),
            $naturalDirection.settingsPublisher(),
            $swipeThreshold.settingsPublisher(),

            // Alternative displays
            $alternativeDisplays.settingsPublisher(debounce: true)
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

        // General settings
        centerCursorOnWorkspaceChange = appSettings.centerCursorOnWorkspaceChange ?? false
        changeWorkspaceOnAppAssign = appSettings.changeWorkspaceOnAppAssign ?? true
        enablePictureInPictureSupport = appSettings.enablePictureInPictureSupport ?? true
        enableWorkspaceTransition = appSettings.enableWorkspaceTransition ?? true

        // Hotkeys
        assignFocusedApp = appSettings.assignFocusedApp
        unassignFocusedApp = appSettings.unassignFocusedApp
        toggleFocusedAppAssignment = appSettings.toggleFocusedAppAssignment
        switchToRecentWorkspace = appSettings.switchToRecentWorkspace
        switchToPreviousWorkspace = appSettings.switchToPreviousWorkspace
        switchToNextWorkspace = appSettings.switchToNextWorkspace

        // Swipe settings
        enableSwipeGesture = appSettings.enableSwipeGesture ?? false
        swipeFingerCount = appSettings.swipeFingerCount == 4 ? .four : .three
        naturalDirection = appSettings.naturalDirection ?? false
        swipeThreshold = appSettings.swipeThreshold ?? 0.3

        // Alternative displays
        alternativeDisplays = appSettings.alternativeDisplays ?? ""

        observe()
        updateSwipeManager()
    }

    func update(_ appSettings: inout AppSettings) {
        // General settings
        appSettings.centerCursorOnWorkspaceChange = centerCursorOnWorkspaceChange
        appSettings.changeWorkspaceOnAppAssign = changeWorkspaceOnAppAssign
        appSettings.enablePictureInPictureSupport = enablePictureInPictureSupport
        appSettings.enableWorkspaceTransition = enableWorkspaceTransition

        // Hotkeys
        appSettings.assignFocusedApp = assignFocusedApp
        appSettings.unassignFocusedApp = unassignFocusedApp
        appSettings.toggleFocusedAppAssignment = toggleFocusedAppAssignment
        appSettings.switchToRecentWorkspace = switchToRecentWorkspace
        appSettings.switchToPreviousWorkspace = switchToPreviousWorkspace
        appSettings.switchToNextWorkspace = switchToNextWorkspace

        // Swipe settings
        appSettings.enableSwipeGesture = enableSwipeGesture
        appSettings.swipeFingerCount = swipeFingerCount.rawValue
        appSettings.naturalDirection = naturalDirection
        appSettings.swipeThreshold = swipeThreshold

        // Alternative displays
        appSettings.alternativeDisplays = alternativeDisplays
    }
}
