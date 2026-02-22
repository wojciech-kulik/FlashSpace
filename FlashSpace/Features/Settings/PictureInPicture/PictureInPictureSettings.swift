//
//  PictureInPictureSettings.swift
//
//  Created by Wojciech Kulik on 22/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class PictureInPictureSettings: ObservableObject {
    @Published var enablePictureInPictureSupport = true
    @Published var switchWorkspaceWhenPipCloses = true
    @Published var pipScreenCornerOffset = 15
    @Published var pipApps: [PipApp] = []

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
            $enablePictureInPictureSupport.settingsPublisher(),
            $switchWorkspaceWhenPipCloses.settingsPublisher(),
            $pipApps.settingsPublisher(),
            $pipScreenCornerOffset.settingsPublisher(debounce: true)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension PictureInPictureSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enablePictureInPictureSupport = appSettings.enablePictureInPictureSupport ?? true
        switchWorkspaceWhenPipCloses = appSettings.switchWorkspaceWhenPipCloses ?? true
        pipApps = appSettings.pipApps ?? []
        pipScreenCornerOffset = appSettings.pipScreenCornerOffset ?? 15
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enablePictureInPictureSupport = enablePictureInPictureSupport
        appSettings.switchWorkspaceWhenPipCloses = switchWorkspaceWhenPipCloses
        appSettings.pipApps = pipApps
        appSettings.pipScreenCornerOffset = pipScreenCornerOffset
    }
}
