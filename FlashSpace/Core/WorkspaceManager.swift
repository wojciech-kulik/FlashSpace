//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class WorkspaceManager {
    private(set) var activeWorkspace: Workspace?

    private var cancellables = Set<AnyCancellable>()
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    init() {
        // Ask for accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)

        hideAgainSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] in self?.hideApps(in: $0) }
            .store(in: &cancellables)
    }

    func activateWorkspace(_ workspace: Workspace) {
        print("\n\nWORKSPACE: \(workspace.name)")
        print("----")

        activeWorkspace = workspace

        let focusedWindowTracker = AppDependencies.shared.focusedWindowTracker
        focusedWindowTracker.stopTracking()
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedWindowTracker.startTracking()
            }
        }

        showApps(in: workspace)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)
    }

    private func showApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let appsToShow = regularApps
            .filter { workspace.apps.contains($0.localizedName ?? "") }

        for app in appsToShow {
            print("SHOW: \(app.localizedName ?? "")")
            app.unhide()
        }

        appsToShow
            .first { $0.localizedName == workspace.apps.last }
            .flatMap(focusApp)
    }

    private func hideApps(in workspace: Workspace) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let hasMoreScreens = NSScreen.screens.count > 1
        let appsToHide = regularApps
            .filter { !workspace.apps.contains($0.localizedName ?? "") && !$0.isHidden }
            .filter { !hasMoreScreens || $0.getFrame()?.getDisplay() == workspace.display }

        for app in appsToHide {
            print("HIDE: \(app.localizedName ?? "")")
            app.hide()
        }
    }

    private func focusApp(_ app: NSRunningApplication) {
        defer { _ = app.activate(options: .activateIgnoringOtherApps) }

        var windowList: CFTypeRef?
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementCopyAttributeValue(appElement, NSAccessibility.Attribute.windows as CFString, &windowList)

        guard let windows = windowList as? [AXUIElement] else {
            return print("No windows found for: \(app.localizedName ?? "")")
        }

        let mainWindow = windows
            .first {
                var isMain: CFTypeRef?
                AXUIElementCopyAttributeValue($0, NSAccessibility.Attribute.main as CFString, &isMain)
                return isMain as? Bool == true
            }

        guard let mainWindow else {
            return print("No main window found for: \(app.localizedName ?? "")")
        }

        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
        AXUIElementSetAttributeValue(appElement, NSAccessibility.Attribute.frontmost as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(mainWindow, NSAccessibility.Attribute.main as CFString, kCFBooleanTrue)
    }
}
