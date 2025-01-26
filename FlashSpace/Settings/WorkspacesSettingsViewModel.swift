import Foundation
import SwiftUI

final class WorkspacesSettingsViewModel: ObservableObject {
    private let settingsRepository = AppDependencies.shared.settingsRepository

    @Published var selectedFloatingApp: String?

    func addFloatingApp() {
        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }

        let appName = appUrl.lastPathComponent.replacingOccurrences(of: ".app", with: "")

        settingsRepository.addFloatingAppIfNeeded(app: appName)
    }

    func deleteFloatingApp() {
        guard let appName = selectedFloatingApp else { return }
        settingsRepository.deleteFloatingApp(app: appName)
        selectedFloatingApp = nil
    }
}
