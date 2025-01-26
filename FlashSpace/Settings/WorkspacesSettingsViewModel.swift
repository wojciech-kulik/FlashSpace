import Foundation
import SwiftUI

final class WorkspacesSettingsViewModel: ObservableObject {
    private let settingsRepository = AppDependencies.shared.settingsRepository

    func addFloatingApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }
        let appName = appUrl.bundle?.localizedAppName ?? appUrl.fileName

        settingsRepository.addFloatingAppIfNeeded(app: appName)
    }

    func deleteFloatingApp(app: String) {
        settingsRepository.deleteFloatingApp(app: app)
    }
}
