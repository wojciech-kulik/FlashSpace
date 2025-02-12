import Foundation
import SwiftUI

final class FloatingAppsSettingsViewModel: ObservableObject {
    private let settingsRepository = AppDependencies.shared.settingsRepository

    func addFloatingApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let bundle = appUrl?.bundle else { return }

        settingsRepository.addFloatingAppIfNeeded(
            app: .init(
                name: bundle.localizedAppName,
                bundleIdentifier: bundle.bundleIdentifier ?? "",
                iconPath: bundle.iconPath
            )
        )
    }

    func deleteFloatingApp(app: MacApp) {
        settingsRepository.deleteFloatingApp(app: app)
    }
}
