//
//  DisplayManager.swift
//
//  Created by Moritz Brödel on 19/06/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

typealias Focus = (display: DisplayName, app: MacApp)

final class DisplayManager: ObservableObject {
    private var displayFocusHistory: [Focus] = []
    private let workspaceSettings: WorkspaceSettings

    init(settingsRepository: SettingsRepository) {
        self.workspaceSettings = settingsRepository.workspaceSettings
    }

    func lastDisplayFocus(where condition: (Focus) -> Bool) -> Focus? {
        displayFocusHistory.last(where: condition)
    }

    func trackDisplayFocus(on display: DisplayName, for application: NSRunningApplication) {
        if application.bundleIdentifier == "com.apple.finder", application.allWindows.count == 0 { return }
        displayFocusHistory.removeAll { $0.display == display }
        displayFocusHistory.append((display: display, app: application.toMacApp))
    }

    func getCursorScreen() -> DisplayName? {
        let cursorLocation = NSEvent.mouseLocation
        return NSScreen.screens
            .first { NSMouseInRect(cursorLocation, $0.frame, false) }?
            .localizedName
    }

    func resolveDisplay(_ display: DisplayName) -> DisplayName {
        if NSScreen.isConnected(display) { return display }

        let alternativeDisplays = workspaceSettings.alternativeDisplays
            .split(separator: ";")
            .map { $0.split(separator: "=") }
            .compactMap { pair -> (source: String, target: String)? in
                guard pair.count == 2 else { return nil }
                return (String(pair[0]).trimmed, String(pair[1]).trimmed)
            }

        let alternative = alternativeDisplays
            .filter { $0.source == display }
            .first { NSScreen.isConnected($0.target) }?
            .target

        return alternative ?? NSScreen.main?.localizedName ?? ""
    }

    func selectDisplay(from candidates: Set<DisplayName>) -> DisplayName {
        if let recentDisplay = lastDisplayFocus(where: { candidates.contains($0.display) })?.display {
            return recentDisplay
        }
        if let cursorDisplay = getCursorScreen(), candidates.contains(cursorDisplay) {
            return cursorDisplay
        }
        return candidates.first ?? NSScreen.main?.localizedName ?? ""
    }
}
