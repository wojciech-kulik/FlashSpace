//
//  MenuBarSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class MenuBarSettings: ObservableObject {
    enum Constants {
        static let maxMinWidth = 300
        static let maxIconSpacing = 40
    }

    static let defaultMenuBarTitleTemplate = "$WORKSPACE"

    @Published var showMenuBar = true
    @Published var showMenuBarTitle = true
    @Published var showMenuBarIcon = true
    @Published var menuBarTitleUseScript = false
    @Published var menuBarTitleScriptPath = ""
    @Published var menuBarTitleTemplate = MenuBarSettings.defaultMenuBarTitleTemplate
    @Published var menuBarDisplayAliases = ""
    @Published var menuBarUseMonospaceFont = false
    @Published var menuBarMinWidth = 20
    @Published var menuBarIconSpacing = 4
    @Published var menuBarBoldTitle = false
    @Published var menuBarBoldIcon = false

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $showMenuBar.settingsPublisher(),
            $showMenuBarTitle.settingsPublisher(),
            $showMenuBarIcon.settingsPublisher(),
            $menuBarTitleUseScript.settingsPublisher(),
            $menuBarTitleScriptPath.settingsPublisher(debounce: true),
            $menuBarTitleTemplate.settingsPublisher(debounce: true),
            $menuBarDisplayAliases.settingsPublisher(debounce: true),
            $menuBarUseMonospaceFont.settingsPublisher(),
            $menuBarMinWidth.settingsPublisher(debounce: true),
            $menuBarIconSpacing.settingsPublisher(debounce: true),
            $menuBarBoldTitle.settingsPublisher(),
            $menuBarBoldIcon.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            self?.validate()
            self?.updateSubject.send()
        }
    }

    private func validate() {
        menuBarMinWidth = max(0, min(Constants.maxMinWidth, menuBarMinWidth))
        menuBarIconSpacing = max(0, min(Constants.maxIconSpacing, menuBarIconSpacing))
    }
}

extension MenuBarSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        showMenuBar = appSettings.showMenuBar ?? true
        showMenuBarTitle = appSettings.showMenuBarTitle ?? true
        showMenuBarIcon = appSettings.showMenuBarIcon ?? true
        menuBarTitleScriptPath = appSettings.menuBarTitleScriptPath ?? ""
        menuBarTitleUseScript = appSettings.menuBarTitleUseScript ?? false
        menuBarTitleTemplate = appSettings.menuBarTitleTemplate ?? Self.defaultMenuBarTitleTemplate
        menuBarDisplayAliases = appSettings.menuBarDisplayAliases ?? ""
        menuBarUseMonospaceFont = appSettings.menuBarUseMonospaceFont ?? false
        menuBarMinWidth = appSettings.menuBarMinWidth ?? 20
        menuBarIconSpacing = appSettings.menuBarIconSpacing ?? 4
        menuBarBoldTitle = appSettings.menuBarBoldTitle ?? false
        menuBarBoldIcon = appSettings.menuBarBoldIcon ?? false
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.showMenuBar = showMenuBar
        appSettings.showMenuBarTitle = showMenuBarTitle
        appSettings.showMenuBarIcon = showMenuBarIcon
        appSettings.menuBarTitleScriptPath = menuBarTitleScriptPath
        appSettings.menuBarTitleUseScript = menuBarTitleUseScript
        appSettings.menuBarTitleTemplate = menuBarTitleTemplate
        appSettings.menuBarDisplayAliases = menuBarDisplayAliases
        appSettings.menuBarUseMonospaceFont = menuBarUseMonospaceFont
        appSettings.menuBarMinWidth = menuBarMinWidth
        appSettings.menuBarIconSpacing = menuBarIconSpacing
        appSettings.menuBarBoldTitle = menuBarBoldTitle
        appSettings.menuBarBoldIcon = menuBarBoldIcon
    }
}
