//
//  GeneralSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class GeneralSettings: ObservableObject {
    @Published var showFlashSpace: AppHotKey?
    @Published var showFloatingNotifications = true
    @Published var checkForUpdatesAutomatically = false {
        didSet { UpdatesManager.shared.autoCheckForUpdates = checkForUpdatesAutomatically }
    }

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $showFlashSpace.settingsPublisher(),
            $checkForUpdatesAutomatically.settingsPublisher(),
            $showFloatingNotifications.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension GeneralSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        showFlashSpace = appSettings.showFlashSpace
        checkForUpdatesAutomatically = appSettings.checkForUpdatesAutomatically ?? false
        showFloatingNotifications = appSettings.showFloatingNotifications ?? true
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.showFlashSpace = showFlashSpace
        appSettings.checkForUpdatesAutomatically = checkForUpdatesAutomatically
        appSettings.showFloatingNotifications = showFloatingNotifications
    }
}
