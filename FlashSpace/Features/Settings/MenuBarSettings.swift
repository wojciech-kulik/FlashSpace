//
//  MenuBarSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class MenuBarSettings: ObservableObject {
    static let defaultMenuBarTitleTemplate = "$WORKSPACE"

    @Published var showMenuBarTitle = true
    @Published var menuBarTitleTemplate = MenuBarSettings.defaultMenuBarTitleTemplate
    @Published var menuBarDisplayAliases = ""

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $showMenuBarTitle.settingsPublisher(),
            $menuBarTitleTemplate.settingsPublisher(debounce: true),
            $menuBarDisplayAliases.settingsPublisher(debounce: true)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension MenuBarSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        showMenuBarTitle = appSettings.showMenuBarTitle ?? true
        menuBarTitleTemplate = appSettings.menuBarTitleTemplate ?? Self.defaultMenuBarTitleTemplate
        menuBarDisplayAliases = appSettings.menuBarDisplayAliases ?? ""
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.showMenuBarTitle = showMenuBarTitle
        appSettings.menuBarTitleTemplate = menuBarTitleTemplate
        appSettings.menuBarDisplayAliases = menuBarDisplayAliases
    }
}
