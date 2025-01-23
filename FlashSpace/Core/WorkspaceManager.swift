//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

typealias DisplayName = String

final class WorkspaceManager {
    private(set) var activeWorkspace: [DisplayName: Workspace] = [:]
    private(set) var lastWorkspaceActivation = Date.distantPast

    private var cancellables = Set<AnyCancellable>()
    private let hideAgainSubject = PassthroughSubject<Workspace, Never>()

    init() {
        // Ask for accessibility permissions
        // Required to hide apps
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)

        hideAgainSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] in self?.hideApps(in: $0) }
            .store(in: &cancellables)
    }

    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        print("\n\nWORKSPACE: \(workspace.name)")
        print("----")

        lastWorkspaceActivation = Date()
        activeWorkspace[workspace.display] = workspace
        showApps(in: workspace, setFocus: setFocus)
        hideApps(in: workspace)

        // Some apps may not hide properly,
        // so we hide apps in the workspace after a short delay
        hideAgainSubject.send(workspace)
    }

    private func showApps(in workspace: Workspace, setFocus: Bool) {
        let regularApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let appsToShow = regularApps
            .filter { workspace.apps.contains($0.localizedName ?? "") }

        for app in appsToShow {
            print("SHOW: \(app.localizedName ?? "")")
            app.unhide()
        }

        if setFocus {
            appsToShow
                .first { $0.localizedName == workspace.apps.last }?
                .focus()
        }
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
}
