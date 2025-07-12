//
//  DisplayManager.swift
//
//  Created by Moritz Brödel on 19/06/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class DisplayManager: ObservableObject {
    struct Focus {
        let display: DisplayName
        let app: MacApp
    }

    private var focusHistory: [Focus] = []
    private let workspaceSettings: WorkspaceSettings

    init(settingsRepository: SettingsRepository) {
        self.workspaceSettings = settingsRepository.workspaceSettings
    }

    func lastFocusedDisplay(where condition: (Focus) -> Bool) -> Focus? {
        focusHistory.last(where: condition)
    }

    func trackDisplayFocus(on display: DisplayName, for application: NSRunningApplication) {
        guard !application.isFinder || application.allWindows.isNotEmpty else { return }

        focusHistory.removeAll { $0.display == display }
        focusHistory.append(.init(display: display, app: application.toMacApp))
    }

    func getCursorScreen() -> DisplayName? {
        let cursorLocation = NSEvent.mouseLocation
        return NSScreen.screens
            .first { NSMouseInRect(cursorLocation, $0.frame, false) }?
            .localizedName
    }

    func resolveDisplay(_ display: DisplayName) -> DisplayName {
        guard !NSScreen.isConnected(display) else { return display }

        let alternativeDisplays = workspaceSettings.alternativeDisplays
            .split(separator: ";")
            .map { $0.split(separator: "=") }
            .compactMap { pair -> (source: String, target: String)? in
                guard pair.count == 2 else { return nil }
                return (String(pair[0]).trimmed, String(pair[1]).trimmed)
            }

        let alternative = alternativeDisplays
            .filter { $0.source == display }
            .map(\.target)
            .first(where: NSScreen.isConnected)

        return alternative ?? NSScreen.main?.localizedName ?? ""
    }

    func lastActiveDisplay(from candidates: Set<DisplayName>) -> DisplayName {
        if let recentDisplay = lastFocusedDisplay(where: { candidates.contains($0.display) })?.display {
            return recentDisplay
        }

        if let cursorDisplay = getCursorScreen(), candidates.contains(cursorDisplay) {
            return cursorDisplay
        }

        return candidates.first ?? NSScreen.main?.localizedName ?? ""
    }
}
