//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import ShortcutRecorder

typealias DisplayName = String

struct ActiveWorkspace {
    let name: String
    let number: String?
    let symbolIconName: String?
    let display: DisplayName
}

final class WorkspaceManager: ObservableObject {
    @Published private(set) var activeWorkspaceDetails: ActiveWorkspace?

    private(set) var lastFocusedApp: [WorkspaceID: MacApp] = [:]
    private(set) var activeWorkspace: [DisplayName: Workspace] = [:]
    private(set) var mostRecentWorkspace: [DisplayName: Workspace] = [:]
    private(set) var lastWorkspaceActivation = Date.distantPast

    private var cancellables = Set<AnyCancellable>()
    private var observeFocusCancellable: AnyCancellable?
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    private let workspaceRepository: WorkspaceRepository
    private let settingsRepository: SettingsRepository

    init(
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceRepository = workspaceRepository
        self.settingsRepository = settingsRepository

        PermissionsManager.shared.askForAccessibilityPermissions()
        observe()
    }

    private func observe() {
        hideAgainSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] in self?.hideApps(in: $0) }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .profileChanged)
            .sink { [weak self] _ in
                self?.lastFocusedApp = [:]
                self?.activeWorkspace = [:]
                self?.mostRecentWorkspace = [:]
                self?.activeWorkspaceDetails = nil
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.activeWorkspace = [:]
                self?.mostRecentWorkspace = [:]
                self?.activeWorkspaceDetails = nil
            }
            .store(in: &cancellables)

        observeFocus()
    }

    private func observeFocus() {
        observeFocusCancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] application in
                guard let self else { return }

                if let activeWorkspace = activeWorkspace[application.display ?? ""],
                   activeWorkspace.apps.containsApp(application) {
                    lastFocusedApp[activeWorkspace.id] = application.toMacApp
                }
            }
    }

    private func showApps(in workspace: Workspace, setFocus: Bool) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let floatingApps = (settingsRepository.floatingApps ?? [])
        var appsToShow = regularApps
            .filter {
                workspace.apps.containsApp($0) ||
                    floatingApps.containsApp($0) &&
                    $0.isOnTheSameScreen(as: workspace)
            }

        observeFocusCancellable = nil
        defer { observeFocus() }

        if setFocus {
            let toFocus = findAppToFocus(in: workspace, apps: appsToShow)

            // Make sure to raise the app that should be focused
            // as the last one
            if let toFocus {
                appsToShow.removeAll { $0 == toFocus }
                appsToShow.append(toFocus)
            }

            for app in appsToShow {
                print("SHOW: \(app.localizedName ?? "")")
                if app == toFocus || app.isHidden || app.isMinimized {
                    app.raise()
                }
            }

            print("FOCUS: \(toFocus?.localizedName ?? "")")
            toFocus?.activate()
            centerCursorIfNeeded(in: toFocus?.frame)
        } else {
            for app in appsToShow {
                print("SHOW: \(app.localizedName ?? "")")
                app.raise()
            }
        }
    }

    private func hideApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let workspaceApps = workspace.apps + (settingsRepository.floatingApps ?? [])
        let isAnyWorkspaceAppRunning = regularApps
            .contains { workspaceApps.containsApp($0) }

        let appsToHide = regularApps
            .filter { !$0.isHidden && !workspaceApps.containsApp($0) }
            .filter { isAnyWorkspaceAppRunning || $0.bundleURL?.fileName != "Finder" }
            .filter { $0.isOnTheSameScreen(as: workspace) }

        for app in appsToHide {
            print("HIDE: \(app.localizedName ?? "")")
            app.hide()
        }
    }

    private func findAppToFocus(
        in workspace: Workspace,
        apps: [NSRunningApplication]
    ) -> NSRunningApplication? {
        var appToFocus: NSRunningApplication?

        if workspace.appToFocus == nil {
            appToFocus = apps.find(lastFocusedApp[workspace.id])
        } else {
            appToFocus = apps.find(workspace.appToFocus)
        }

        let fallbackToLastApp = apps.find(workspace.apps.last)
        let fallbackToFinder = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == "com.apple.finder" }

        return appToFocus ?? fallbackToLastApp ?? fallbackToFinder
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard settingsRepository.centerCursorOnWorkspaceChange, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func updateActiveWorkspace(_ workspace: Workspace) {
        lastWorkspaceActivation = Date()

        // Save the most recent workspace if it's not the current one
        let display = workspace.displayWithFallback
        if activeWorkspace[display]?.id != workspace.id {
            mostRecentWorkspace[display] = activeWorkspace[display]
        }

        activeWorkspace[display] = workspace

        activeWorkspaceDetails = .init(
            name: workspace.name,
            number: workspaceRepository.workspaces
                .firstIndex { $0.id == workspace.id }
                .map { "\($0 + 1)" },
            symbolIconName: workspace.symbolIconName,
            display: display
        )

        Integrations.runOnActivateIfNeeded(workspace: activeWorkspaceDetails!)
    }
}

// MARK: - Workspace Actions
extension WorkspaceManager {
    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        print("\n\nWORKSPACE: \(workspace.name)")
        print("----")

        updateActiveWorkspace(workspace)
        showApps(in: workspace, setFocus: setFocus)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)
    }

    func assignApp(_ app: MacApp, to workspace: Workspace) {
        workspaceRepository.deleteAppFromAllWorkspaces(app: app)
        workspaceRepository.addApp(to: workspace.id, app: app)

        guard let targetWorkspace = workspaceRepository.workspaces
            .first(where: { $0.id == workspace.id }) else { return }

        let isTargetWorkspaceActive = activeWorkspace.values
            .contains(where: { $0.id == workspace.id })

        updateLastFocusedApp(app, in: targetWorkspace)

        if settingsRepository.changeWorkspaceOnAppAssign {
            activateWorkspace(targetWorkspace, setFocus: true)
        } else if !isTargetWorkspaceActive {
            NSWorkspace.shared.runningApplications
                .find(app)?
                .hide()
            AppDependencies.shared.focusManager.nextWorkspaceApp()
        }

        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    func updateLastFocusedApp(_ app: MacApp, in workspace: Workspace) {
        lastFocusedApp[workspace.id] = app
    }
}
