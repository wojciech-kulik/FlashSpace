//
//  FloatingAppsSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class FloatingAppsSettings: ObservableObject {
    @Published var floatingApps: [MacApp] = []
    @Published var floatTheFocusedApp: AppHotKey?
    @Published var unfloatTheFocusedApp: AppHotKey?
    @Published var toggleTheFocusedAppFloating: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    func addFloatingAppIfNeeded(app: MacApp) {
        guard !floatingApps.contains(app) else { return }
        floatingApps.append(app)
    }

    func deleteFloatingApp(app: MacApp) {
        floatingApps.removeAll { $0 == app }
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $floatingApps.settingsPublisher(),
            $floatTheFocusedApp.settingsPublisher(),
            $unfloatTheFocusedApp.settingsPublisher(),
            $toggleTheFocusedAppFloating.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension FloatingAppsSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        floatingApps = appSettings.floatingApps ?? []
        floatTheFocusedApp = appSettings.floatTheFocusedApp
        unfloatTheFocusedApp = appSettings.unfloatTheFocusedApp
        toggleTheFocusedAppFloating = appSettings.toggleTheFocusedAppFloating
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.floatingApps = floatingApps.isEmpty ? nil : floatingApps
        appSettings.floatTheFocusedApp = floatTheFocusedApp
        appSettings.unfloatTheFocusedApp = unfloatTheFocusedApp
        appSettings.toggleTheFocusedAppFloating = toggleTheFocusedAppFloating
    }
}
