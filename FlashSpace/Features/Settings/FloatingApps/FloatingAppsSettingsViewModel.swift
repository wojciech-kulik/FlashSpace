import Foundation
import SwiftUI

final class FloatingAppsSettingsViewModel: ObservableObject {
    private let settings = AppDependencies.shared.floatingAppsSettings

    func addFloatingApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let bundle = appUrl?.bundle else { return }

        settings.addFloatingAppIfNeeded(
            app: .init(
                name: bundle.localizedAppName,
                bundleIdentifier: bundle.bundleIdentifier ?? "",
                iconPath: bundle.iconPath,
                autoOpen: nil
            )
        )
    }

    func deleteFloatingApp(app: MacApp) {
        settings.deleteFloatingApp(app: app)
    }
}
