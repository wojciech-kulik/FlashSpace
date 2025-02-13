//
//  SettingsRepository.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

struct AppSettings: Codable {
    var checkForUpdatesAutomatically: Bool?
    var showFlashSpace: HotKeyShortcut?

    var showMenuBarTitle: Bool?
    var menuBarTitleTemplate: String?
    var menuBarDisplayAliases: String?

    var enableFocusManagement: Bool?
    var centerCursorOnFocusChange: Bool?
    var focusLeft: HotKeyShortcut?
    var focusRight: HotKeyShortcut?
    var focusUp: HotKeyShortcut?
    var focusDown: HotKeyShortcut?
    var focusNextWorkspaceApp: HotKeyShortcut?
    var focusPreviousWorkspaceApp: HotKeyShortcut?
    var focusNextWorkspaceWindow: HotKeyShortcut?
    var focusPreviousWorkspaceWindow: HotKeyShortcut?

    var centerCursorOnWorkspaceChange: Bool?
    var switchToPreviousWorkspace: HotKeyShortcut?
    var switchToNextWorkspace: HotKeyShortcut?
    var switchToRecentWorkspace: HotKeyShortcut?
    var assignFocusedApp: HotKeyShortcut?
    var unassignFocusedApp: HotKeyShortcut?
    var showFloatingNotifications: Bool?
    var changeWorkspaceOnAppAssign: Bool?
    var enablePictureInPictureSupport: Bool?

    var floatingApps: [MacApp]?
    var floatTheFocusedApp: HotKeyShortcut?
    var unfloatTheFocusedApp: HotKeyShortcut?

    var enableSpaceControl: Bool?
    var showSpaceControl: HotKeyShortcut?
    var enableSpaceControlAnimations: Bool?
    var spaceControlCurrentDisplayWorkspaces: Bool?

    var enableIntegrations: Bool?
    var runScriptOnWorkspaceChange: String?
    var runScriptOnLaunch: String?
    var runScriptOnProfileChange: String?
}

final class SettingsRepository: ObservableObject {
    static let defaultScript = "sketchybar --trigger flashspace_workspace_change WORKSPACE=\"$WORKSPACE\" DISPLAY=\"$DISPLAY\""
    static let defaultProfileChangeScript = "sketchybar --reload"
    static let defaultMenuBarTitleTemplate = "$WORKSPACE"

    // MARK: - General

    @Published var showFlashSpace: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var checkForUpdatesAutomatically: Bool = false {
        didSet { updateSettings() }
    }

    @Published var showMenuBarTitle: Bool = true {
        didSet { updateSettings() }
    }

    // MARK: - Menu Bar

    @Published var menuBarTitleTemplate: String = SettingsRepository.defaultMenuBarTitleTemplate {
        didSet { debouncedUpdateSettings.send(()) }
    }

    @Published var menuBarDisplayAliases: String = "" {
        didSet { debouncedUpdateSettings.send(()) }
    }

    // MARK: - Focus Manager

    @Published var enableFocusManagement: Bool = false {
        didSet { updateSettings() }
    }

    @Published var centerCursorOnFocusChange: Bool = false {
        didSet { updateSettings() }
    }

    @Published var focusLeft: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusRight: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusUp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusDown: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusNextWorkspaceApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusPreviousWorkspaceApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusNextWorkspaceWindow: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var focusPreviousWorkspaceWindow: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    // MARK: - Workspaces

    @Published var centerCursorOnWorkspaceChange: Bool = false {
        didSet { updateSettings() }
    }

    @Published var switchToPreviousWorkspace: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var switchToNextWorkspace: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var switchToRecentWorkspace: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var assignFocusedApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var unassignFocusedApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var floatingApps: [MacApp]? {
        didSet { updateSettings() }
    }

    @Published var floatTheFocusedApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var unfloatTheFocusedApp: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var showFloatingNotifications: Bool = true {
        didSet { updateSettings() }
    }

    @Published var changeWorkspaceOnAppAssign: Bool = true {
        didSet { updateSettings() }
    }

    @Published var enablePictureInPictureSupport: Bool = true {
        didSet { updateSettings() }
    }

    // MARK: - SpaceControl

    @Published var enableSpaceControl: Bool = false {
        didSet { updateSettings() }
    }

    @Published var showSpaceControl: HotKeyShortcut? {
        didSet { updateSettings() }
    }

    @Published var enableSpaceControlAnimations: Bool = true {
        didSet { updateSettings() }
    }

    @Published var spaceControlCurrentDisplayWorkspaces: Bool = false {
        didSet { updateSettings() }
    }

    // MARK: - Integrations

    @Published var enableIntegrations: Bool = false {
        didSet { updateSettings() }
    }

    @Published var runScriptOnWorkspaceChange: String = "" {
        didSet { debouncedUpdateSettings.send(()) }
    }

    @Published var runScriptOnLaunch: String = "" {
        didSet { debouncedUpdateSettings.send(()) }
    }

    @Published var runScriptOnProfileChange: String = "" {
        didSet { debouncedUpdateSettings.send(()) }
    }

    private var currentSettings = AppSettings()
    private var shouldUpdate = false
    private var cancellables = Set<AnyCancellable>()

    private let debouncedUpdateSettings = PassthroughSubject<(), Never>()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dataUrl = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashspace/settings.json")

    init() {
        encoder.outputFormatting = .prettyPrinted
        loadFromDisk()

        debouncedUpdateSettings
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.updateSettings() }
            .store(in: &cancellables)

        DispatchQueue.main.async {
            Integrations.runOnAppLaunchIfNeeded()
        }
    }

    func addFloatingAppIfNeeded(app: MacApp) {
        var unwrappedFloatingApps = floatingApps ?? []
        guard !unwrappedFloatingApps.contains(app) else { return }
        unwrappedFloatingApps.append(app)
        floatingApps = unwrappedFloatingApps
        saveToDisk()
    }

    func deleteFloatingApp(app: MacApp) {
        floatingApps?.removeAll { $0 == app }
        saveToDisk()
    }

    func saveToDisk() {
        guard let data = try? encoder.encode(currentSettings) else { return }

        try? dataUrl.createIntermediateDirectories()
        try? data.write(to: dataUrl)
    }

    private func updateSettings() {
        guard shouldUpdate else { return }

        currentSettings = AppSettings(
            checkForUpdatesAutomatically: checkForUpdatesAutomatically,
            showFlashSpace: showFlashSpace,

            showMenuBarTitle: showMenuBarTitle,
            menuBarTitleTemplate: menuBarTitleTemplate,
            menuBarDisplayAliases: menuBarDisplayAliases,

            enableFocusManagement: enableFocusManagement,
            centerCursorOnFocusChange: centerCursorOnFocusChange,
            focusLeft: focusLeft,
            focusRight: focusRight,
            focusUp: focusUp,
            focusDown: focusDown,
            focusNextWorkspaceApp: focusNextWorkspaceApp,
            focusPreviousWorkspaceApp: focusPreviousWorkspaceApp,
            focusNextWorkspaceWindow: focusNextWorkspaceWindow,
            focusPreviousWorkspaceWindow: focusPreviousWorkspaceWindow,

            centerCursorOnWorkspaceChange: centerCursorOnWorkspaceChange,
            switchToPreviousWorkspace: switchToPreviousWorkspace,
            switchToNextWorkspace: switchToNextWorkspace,
            switchToRecentWorkspace: switchToRecentWorkspace,
            assignFocusedApp: assignFocusedApp,
            unassignFocusedApp: unassignFocusedApp,

            showFloatingNotifications: showFloatingNotifications,
            changeWorkspaceOnAppAssign: changeWorkspaceOnAppAssign,
            enablePictureInPictureSupport: enablePictureInPictureSupport,

            floatingApps: floatingApps,
            floatTheFocusedApp: floatTheFocusedApp,
            unfloatTheFocusedApp: unfloatTheFocusedApp,

            enableSpaceControl: enableSpaceControl,
            showSpaceControl: showSpaceControl,
            enableSpaceControlAnimations: enableSpaceControlAnimations,
            spaceControlCurrentDisplayWorkspaces: spaceControlCurrentDisplayWorkspaces,

            enableIntegrations: enableIntegrations,
            runScriptOnWorkspaceChange: runScriptOnWorkspaceChange,
            runScriptOnLaunch: runScriptOnLaunch,
            runScriptOnProfileChange: runScriptOnProfileChange
        )
        saveToDisk()
        AppDependencies.shared.hotKeysManager.refresh()
    }

    private func loadFromDisk() {
        shouldUpdate = false
        defer { shouldUpdate = true }

        guard FileManager.default.fileExists(atPath: dataUrl.path) else { return }
        guard let data = try? Data(contentsOf: dataUrl) else { return }
        guard let settings = try? decoder.decode(AppSettings.self, from: data) else { return }

        currentSettings = settings

        checkForUpdatesAutomatically = settings.checkForUpdatesAutomatically ?? false
        showFlashSpace = settings.showFlashSpace

        showMenuBarTitle = settings.showMenuBarTitle ?? true
        menuBarTitleTemplate = settings.menuBarTitleTemplate ?? Self.defaultMenuBarTitleTemplate
        menuBarDisplayAliases = settings.menuBarDisplayAliases ?? ""

        enableFocusManagement = settings.enableFocusManagement ?? false
        centerCursorOnFocusChange = settings.centerCursorOnFocusChange ?? false
        focusLeft = settings.focusLeft
        focusRight = settings.focusRight
        focusUp = settings.focusUp
        focusDown = settings.focusDown
        focusNextWorkspaceApp = settings.focusNextWorkspaceApp
        focusPreviousWorkspaceApp = settings.focusPreviousWorkspaceApp
        focusNextWorkspaceWindow = settings.focusNextWorkspaceWindow
        focusPreviousWorkspaceWindow = settings.focusPreviousWorkspaceWindow

        centerCursorOnWorkspaceChange = settings.centerCursorOnWorkspaceChange ?? false
        switchToPreviousWorkspace = settings.switchToPreviousWorkspace
        switchToNextWorkspace = settings.switchToNextWorkspace
        switchToRecentWorkspace = settings.switchToRecentWorkspace
        assignFocusedApp = settings.assignFocusedApp
        unassignFocusedApp = settings.unassignFocusedApp

        showFloatingNotifications = settings.showFloatingNotifications ?? true
        changeWorkspaceOnAppAssign = settings.changeWorkspaceOnAppAssign ?? true
        enablePictureInPictureSupport = settings.enablePictureInPictureSupport ?? true

        floatingApps = settings.floatingApps
        floatTheFocusedApp = settings.floatTheFocusedApp
        unfloatTheFocusedApp = settings.unfloatTheFocusedApp

        enableSpaceControl = settings.enableSpaceControl ?? false
        showSpaceControl = settings.showSpaceControl
        enableSpaceControlAnimations = settings.enableSpaceControlAnimations ?? true
        spaceControlCurrentDisplayWorkspaces = settings.spaceControlCurrentDisplayWorkspaces ?? false

        enableIntegrations = settings.enableIntegrations ?? false
        runScriptOnWorkspaceChange = settings.runScriptOnWorkspaceChange ?? Self.defaultScript
        runScriptOnLaunch = settings.runScriptOnLaunch ?? ""
        runScriptOnProfileChange = settings.runScriptOnProfileChange ?? Self.defaultProfileChangeScript
    }
}
