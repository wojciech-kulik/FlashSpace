//
//  WorkspaceSwitcherSettings.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation
import KeyboardShortcuts

final class WorkspaceSwitcherSettings: ObservableObject {
    @Published var enableWorkspaceSwitcher = true
    @Published var showWorkspaceSwitcher: AppHotKey?
    @Published var workspaceSwitcherShowScreenshots = true
    @Published var workspaceSwitcherVisibleWorkspaces = 5
    @Published var workspaceSwitcherSortByLastActivation = false
    // swiftlint:disable:next identifier_name
    @Published var workspaceSwitcherCurrentDisplayWorkspaces = true

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableWorkspaceSwitcher.settingsPublisher(),
            $showWorkspaceSwitcher.settingsPublisher(),
            $workspaceSwitcherShowScreenshots.settingsPublisher(),
            $workspaceSwitcherVisibleWorkspaces.settingsPublisher(debounce: true),
            $workspaceSwitcherSortByLastActivation.settingsPublisher(),
            $workspaceSwitcherCurrentDisplayWorkspaces.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }

    func validateShortcut(_ hotKey: AppHotKey?) {
        guard let hotKey else { return }

        let components = hotKey.value.split(separator: "+").map { String($0).lowercased() }
        guard components.contains("shift") else { return }

        Alert.showOkAlert(
            title: "Invalid Shortcut",
            message: "The Workspace Switcher shortcut cannot contain the Shift modifier. " +
                "A variant with Shift will be automatically registered for backward navigation."
        )

        DispatchQueue.main.async {
            KeyboardShortcuts.setShortcut(nil, for: .workspaceSwitcher)
            KeyboardShortcuts.setShortcut(nil, for: .workspaceSwitcherBackward)
            self.showWorkspaceSwitcher = nil
        }
    }
}

extension WorkspaceSwitcherSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enableWorkspaceSwitcher = appSettings.enableWorkspaceSwitcher ?? true
        showWorkspaceSwitcher = appSettings.showWorkspaceSwitcher ?? AppHotKey(value: "opt+tab")
        workspaceSwitcherShowScreenshots = appSettings.workspaceSwitcherShowScreenshots ?? true
        workspaceSwitcherVisibleWorkspaces = max(1, appSettings.workspaceSwitcherVisibleWorkspaces ?? 5)
        workspaceSwitcherSortByLastActivation = appSettings.workspaceSwitcherSortByLastActivation ?? false
        workspaceSwitcherCurrentDisplayWorkspaces = appSettings.workspaceSwitcherCurrentDisplayWorkspaces ?? true
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableWorkspaceSwitcher = enableWorkspaceSwitcher
        appSettings.showWorkspaceSwitcher = showWorkspaceSwitcher
        appSettings.workspaceSwitcherShowScreenshots = workspaceSwitcherShowScreenshots
        appSettings.workspaceSwitcherVisibleWorkspaces = workspaceSwitcherVisibleWorkspaces
        appSettings.workspaceSwitcherSortByLastActivation = workspaceSwitcherSortByLastActivation
        appSettings.workspaceSwitcherCurrentDisplayWorkspaces = workspaceSwitcherCurrentDisplayWorkspaces
    }
}
