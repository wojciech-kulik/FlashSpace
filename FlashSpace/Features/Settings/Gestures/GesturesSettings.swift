//
//  GesturesSettings.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class GesturesSettings: ObservableObject {
    @Published var swipeThreshold: Double = 0.2
    @Published var enableSwipeGestures = false {
        didSet { updateSwipeManager() }
    }

    @Published var restartAppOnWakeUp = false

    @Published var swipeRight3FingerAction: GestureAction = .nextWorkspace
    @Published var swipeLeft3FingerAction: GestureAction = .previousWorkspace
    @Published var swipeRight4FingerAction: GestureAction = .none
    @Published var swipeLeft4FingerAction: GestureAction = .none

    @Published var swipeUp3FingerAction: GestureAction = .none
    @Published var swipeDown3FingerAction: GestureAction = .none
    @Published var swipeUp4FingerAction: GestureAction = .none
    @Published var swipeDown4FingerAction: GestureAction = .none

    var isVerticalSwipeSet: Bool {
        swipeUp3FingerAction != .none || swipeDown3FingerAction != .none ||
            swipeUp4FingerAction != .none || swipeDown4FingerAction != .none
    }

    var isHorizontalSwipeSet: Bool {
        swipeLeft3FingerAction != .none || swipeRight3FingerAction != .none ||
            swipeLeft4FingerAction != .none || swipeRight4FingerAction != .none
    }

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() {
        observe()
        updateSwipeManager()
    }

    private func observe() {
        observer = Publishers.MergeMany(
            $enableSwipeGestures.settingsPublisher(),
            $swipeThreshold.settingsPublisher(),
            $restartAppOnWakeUp.settingsPublisher(),

            $swipeLeft3FingerAction.settingsPublisher(),
            $swipeRight3FingerAction.settingsPublisher(),
            $swipeLeft4FingerAction.settingsPublisher(),
            $swipeRight4FingerAction.settingsPublisher(),

            $swipeUp3FingerAction.settingsPublisher(),
            $swipeDown3FingerAction.settingsPublisher(),
            $swipeUp4FingerAction.settingsPublisher(),
            $swipeDown4FingerAction.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }

    private func updateSwipeManager() {
        if enableSwipeGestures {
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
        enableSwipeGestures = appSettings.enableSwipeGestures ?? false
        swipeThreshold = appSettings.swipeThreshold ?? 0.2
        restartAppOnWakeUp = appSettings.restartAppOnWakeUp ?? false

        swipeLeft3FingerAction = appSettings.swipeLeft3FingerAction ?? .previousWorkspace
        swipeRight3FingerAction = appSettings.swipeRight3FingerAction ?? .nextWorkspace
        swipeLeft4FingerAction = appSettings.swipeLeft4FingerAction ?? .none
        swipeRight4FingerAction = appSettings.swipeRight4FingerAction ?? .none

        swipeUp3FingerAction = appSettings.swipeUp3FingerAction ?? .none
        swipeDown3FingerAction = appSettings.swipeDown3FingerAction ?? .none
        swipeUp4FingerAction = appSettings.swipeUp4FingerAction ?? .none
        swipeDown4FingerAction = appSettings.swipeDown4FingerAction ?? .none

        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.enableSwipeGestures = enableSwipeGestures
        appSettings.swipeThreshold = swipeThreshold
        appSettings.restartAppOnWakeUp = restartAppOnWakeUp

        appSettings.swipeLeft3FingerAction = swipeLeft3FingerAction
        appSettings.swipeRight3FingerAction = swipeRight3FingerAction
        appSettings.swipeLeft4FingerAction = swipeLeft4FingerAction
        appSettings.swipeRight4FingerAction = swipeRight4FingerAction

        appSettings.swipeUp3FingerAction = swipeUp3FingerAction
        appSettings.swipeDown3FingerAction = swipeDown3FingerAction
        appSettings.swipeUp4FingerAction = swipeUp4FingerAction
        appSettings.swipeDown4FingerAction = swipeDown4FingerAction
    }
}
