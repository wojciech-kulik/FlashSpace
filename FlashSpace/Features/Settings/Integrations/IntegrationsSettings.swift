//
//  IntegrationsSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class IntegrationsSettings: ObservableObject {
    static let defaultWorkspaceChangeScript = "sketchybar --trigger flashspace_workspace_change WORKSPACE=\"$WORKSPACE\" DISPLAY=\"$DISPLAY\""
    static let defaultProfileChangeScript = "sketchybar --reload"

    @Published var enableIntegrations = false
    @Published var runScriptOnLaunch = ""
    @Published var runScriptBeforeWorkspaceChange = ""
    @Published var runScriptOnWorkspaceChange = IntegrationsSettings.defaultWorkspaceChangeScript
    @Published var runScriptOnProfileChange = IntegrationsSettings.defaultProfileChangeScript

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() {
        observe()

        DispatchQueue.main.async {
            Integrations.runOnAppLaunchIfNeeded()
        }
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableIntegrations.settingsPublisher(),
            $runScriptBeforeWorkspaceChange.settingsPublisher(debounce: true),
            $runScriptOnWorkspaceChange.settingsPublisher(debounce: true),
            $runScriptOnLaunch.settingsPublisher(debounce: true),
            $runScriptOnProfileChange.settingsPublisher(debounce: true)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension IntegrationsSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enableIntegrations = appSettings.enableIntegrations ?? false
        runScriptOnLaunch = appSettings.runScriptOnLaunch ?? ""
        runScriptBeforeWorkspaceChange = appSettings.runScriptBeforeWorkspaceChange ?? ""
        runScriptOnWorkspaceChange = appSettings.runScriptOnWorkspaceChange ?? Self.defaultWorkspaceChangeScript
        runScriptOnProfileChange = appSettings.runScriptOnProfileChange ?? Self.defaultProfileChangeScript
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableIntegrations = enableIntegrations
        appSettings.runScriptOnLaunch = runScriptOnLaunch
        appSettings.runScriptBeforeWorkspaceChange = runScriptBeforeWorkspaceChange
        appSettings.runScriptOnWorkspaceChange = runScriptOnWorkspaceChange
        appSettings.runScriptOnProfileChange = runScriptOnProfileChange
    }
}
