//
//  WorkspaceSettingsViewModel.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class WorkspaceSettingsViewModel: ObservableObject {
    @Published var windowTitleRegex = ""
    @Published var isInputDialogPresented = false {
        didSet {
            if !isInputDialogPresented, windowTitleRegex.isNotEmpty {
                addPendingPipApp()
                windowTitleRegex = ""
            }
        }
    }

    private var pendingApp: PipApp?
    private let settings = AppDependencies.shared.workspaceSettings

    func addPipApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let bundle = appUrl?.bundle else { return }

        pendingApp = PipApp(
            name: bundle.localizedAppName,
            bundleIdentifier: bundle.bundleIdentifier ?? "",
            pipWindowTitleRegex: ""
        )
        isInputDialogPresented = true
    }

    func deletePipApp(_ app: PipApp) {
        settings.deletePipApp(app)
    }

    private func addPendingPipApp() {
        guard let pendingApp else { return }

        settings.addPipApp(
            .init(
                name: pendingApp.name,
                bundleIdentifier: pendingApp.bundleIdentifier,
                pipWindowTitleRegex: windowTitleRegex
            )
        )
        self.pendingApp = nil
    }
}
