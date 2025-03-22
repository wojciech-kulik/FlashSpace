//
//  GesturesSettings.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class GesturesSettings: ObservableObject {
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

    @Published var enableSwipeGesture = false {
        didSet { updateSwipeManager() }
    }

    @Published var swipeFingerCount: FingerCount = .three {
        didSet { updateSwipeManager() }
    }

    @Published var swipeNaturalDirection = false
    @Published var swipeThreshold: Double = 0.2

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() {
        observe()
        updateSwipeManager()
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableSwipeGesture.settingsPublisher(),
            $swipeFingerCount.settingsPublisher(),
            $swipeNaturalDirection.settingsPublisher(),
            $swipeThreshold.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }

    private func updateSwipeManager() {
        if enableSwipeGesture {
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
        enableSwipeGesture = appSettings.enableSwipeGesture ?? false
        swipeFingerCount = appSettings.swipeFingerCount == 4 ? .four : .three
        swipeNaturalDirection = appSettings.swipeNaturalDirection ?? false
        swipeThreshold = appSettings.swipeThreshold ?? 0.2
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableSwipeGesture = enableSwipeGesture
        appSettings.swipeFingerCount = swipeFingerCount.rawValue
        appSettings.swipeNaturalDirection = swipeNaturalDirection
        appSettings.swipeThreshold = swipeThreshold
    }
}
