//
//  WorkspaceSettingsViewModel.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

final class WorkspaceSettingsViewModel: ObservableObject {
    private let settings = AppDependencies.shared.workspaceSettings

    func addCornerHiddenApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let bundle = appUrl?.bundle else { return }

        settings.addCornerHiddenApp(
            CornerHiddenApp(
                name: bundle.localizedAppName,
                bundleIdentifier: bundle.bundleIdentifier ?? ""
            )
        )
    }

    func deleteCornerHiddenApp(_ app: CornerHiddenApp) {
        settings.deleteCornerHiddenApp(app)
    }
}
