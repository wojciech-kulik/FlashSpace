//
//  Alerts.swift
//
//  Created by Wojciech Kulik on 25/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

func showOkAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func showNewReleaseAlert(release: ReleaseInfo) {
    let alert = NSAlert()
    alert.messageText = "New version available"
    alert.informativeText = "Version \(release.version) is available. Would you like to download it?"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Download")
    alert.addButton(withTitle: "Cancel")

    if alert.runModal() == .alertFirstButtonReturn {
        DispatchQueue.main.async {
            NSWorkspace.shared.open(release.release.htmlUrl)
        }
    }
}
