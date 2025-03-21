//
//  FocusManagerSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class FocusManagerSettings: ObservableObject {
    @Published var enableFocusManagement = false
    @Published var centerCursorOnFocusChange = false

    @Published var focusLeft: AppHotKey?
    @Published var focusRight: AppHotKey?
    @Published var focusUp: AppHotKey?
    @Published var focusDown: AppHotKey?
    @Published var focusNextWorkspaceApp: AppHotKey?
    @Published var focusPreviousWorkspaceApp: AppHotKey?
    @Published var focusNextWorkspaceWindow: AppHotKey?
    @Published var focusPreviousWorkspaceWindow: AppHotKey?
    @Published var focusFrontmostWindow = false

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableFocusManagement.settingsPublisher(),
            $centerCursorOnFocusChange.settingsPublisher(),
            $focusLeft.settingsPublisher(),
            $focusRight.settingsPublisher(),
            $focusUp.settingsPublisher(),
            $focusDown.settingsPublisher(),
            $focusNextWorkspaceApp.settingsPublisher(),
            $focusPreviousWorkspaceApp.settingsPublisher(),
            $focusNextWorkspaceWindow.settingsPublisher(),
            $focusPreviousWorkspaceWindow.settingsPublisher(),
            $focusFrontmostWindow.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension FocusManagerSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enableFocusManagement = appSettings.enableFocusManagement ?? false
        centerCursorOnFocusChange = appSettings.centerCursorOnFocusChange ?? false
        focusLeft = appSettings.focusLeft
        focusRight = appSettings.focusRight
        focusUp = appSettings.focusUp
        focusDown = appSettings.focusDown
        focusNextWorkspaceApp = appSettings.focusNextWorkspaceApp
        focusPreviousWorkspaceApp = appSettings.focusPreviousWorkspaceApp
        focusNextWorkspaceWindow = appSettings.focusNextWorkspaceWindow
        focusPreviousWorkspaceWindow = appSettings.focusPreviousWorkspaceWindow
        focusFrontmostWindow = appSettings.focusFrontmostWindow ?? false
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableFocusManagement = enableFocusManagement
        appSettings.centerCursorOnFocusChange = centerCursorOnFocusChange
        appSettings.focusLeft = focusLeft
        appSettings.focusRight = focusRight
        appSettings.focusUp = focusUp
        appSettings.focusDown = focusDown
        appSettings.focusNextWorkspaceApp = focusNextWorkspaceApp
        appSettings.focusPreviousWorkspaceApp = focusPreviousWorkspaceApp
        appSettings.focusNextWorkspaceWindow = focusNextWorkspaceWindow
        appSettings.focusPreviousWorkspaceWindow = focusPreviousWorkspaceWindow
        appSettings.focusFrontmostWindow = focusFrontmostWindow
    }
}
