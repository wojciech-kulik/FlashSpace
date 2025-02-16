//
//  UpdatesManager.swift
//
//  Created by Wojciech Kulik on 25/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: URL
}

struct ReleaseInfo {
    let isNewer: Bool
    let version: String
    let release: GitHubRelease
}

final class UpdatesManager {
    static let shared = UpdatesManager()

    private var lastCheckDate = Date.distantPast
    private var detectedNewRelease = false

    private init() {}

    @MainActor
    func checkForUpdates() async -> Result<ReleaseInfo, Error> {
        let url = URL(string: "https://api.github.com/repos/wojciech-kulik/FlashSpace/releases/latest")!

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let release = try decoder.decode(GitHubRelease.self, from: data)
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")

            let releaseInfo = ReleaseInfo(
                isNewer: latestVersion != currentVersion,
                version: latestVersion,
                release: release
            )

            return .success(releaseInfo)
        } catch {
            Logger.log(error)
            return .failure(error)
        }
    }

    @MainActor
    func showIfNewReleaseAvailable(silent: Bool = false) async {
        let result = await checkForUpdates()

        switch result {
        case .success(let releaseInfo):
            lastCheckDate = Date()

            if releaseInfo.isNewer {
                detectedNewRelease = true
                Alert.showNewReleaseAlert(release: releaseInfo)
            } else if !silent {
                Alert.showOkAlert(title: "No updates available", message: "You're using the latest version of FlashSpace.")
            }
        case .failure(let error):
            if !silent {
                Alert.showOkAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    @MainActor
    func autoCheckForUpdates() async {
        guard AppDependencies.shared.generalSettings.checkForUpdatesAutomatically else { return }
        guard Date().timeIntervalSince(lastCheckDate) > 30 * 60 else { return }
        guard !detectedNewRelease else { return }

        await showIfNewReleaseAvailable(silent: true)
    }
}
