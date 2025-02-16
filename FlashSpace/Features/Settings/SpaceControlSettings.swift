//
//  SpaceControlSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class SpaceControlSettings: ObservableObject {
    @Published var enableSpaceControl = false
    @Published var showSpaceControl: AppHotKey?
    @Published var enableSpaceControlAnimations = true
    @Published var spaceControlCurrentDisplayWorkspaces = false

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableSpaceControl.settingsPublisher(),
            $showSpaceControl.settingsPublisher(),
            $enableSpaceControlAnimations.settingsPublisher(),
            $spaceControlCurrentDisplayWorkspaces.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension SpaceControlSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enableSpaceControl = appSettings.enableSpaceControl ?? false
        showSpaceControl = appSettings.showSpaceControl
        enableSpaceControlAnimations = appSettings.enableSpaceControlAnimations ?? true
        spaceControlCurrentDisplayWorkspaces = appSettings.spaceControlCurrentDisplayWorkspaces ?? false
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableSpaceControl = enableSpaceControl
        appSettings.showSpaceControl = showSpaceControl
        appSettings.enableSpaceControlAnimations = enableSpaceControlAnimations
        appSettings.spaceControlCurrentDisplayWorkspaces = spaceControlCurrentDisplayWorkspaces
    }
}
