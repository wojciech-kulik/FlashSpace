//
//  ProfileSettings.swift
//
//  Created by Wojciech Kulik on 21/09/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class ProfileSettings: ObservableObject {
    @Published var switchToPreviousProfile: AppHotKey?
    @Published var switchToNextProfile: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $switchToPreviousProfile.settingsPublisher(),
            $switchToNextProfile.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension ProfileSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil

        switchToPreviousProfile = appSettings.switchToPreviousProfile
        switchToNextProfile = appSettings.switchToNextProfile

        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.switchToPreviousProfile = switchToPreviousProfile
        appSettings.switchToNextProfile = switchToNextProfile
    }
}
