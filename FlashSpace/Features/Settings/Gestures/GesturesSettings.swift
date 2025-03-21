//
//  GesturesSettings.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class GesturesSettings: ObservableObject {
    @Published var enableThreeFingersSwipe = false {
        didSet { updateSwipeManager() }
    }

    @Published var naturalDirection = false
    @Published var swipeThreshold: Double = 0.3

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() {
        observe()
        updateSwipeManager()
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableThreeFingersSwipe.settingsPublisher(),
            $naturalDirection.settingsPublisher(),
            $swipeThreshold.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }

    private func updateSwipeManager() {
        if enableThreeFingersSwipe {
            SwipeManager.shared.start()
        } else {
            SwipeManager.shared.stop()
        }
    }
}

extension GesturesSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        enableThreeFingersSwipe = appSettings.enableThreeFingersSwipe ?? false
        naturalDirection = appSettings.naturalDirection ?? false
        swipeThreshold = appSettings.swipeThreshold ?? 0.3
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableThreeFingersSwipe = enableThreeFingersSwipe
        appSettings.naturalDirection = naturalDirection
        appSettings.swipeThreshold = swipeThreshold
    }
}
