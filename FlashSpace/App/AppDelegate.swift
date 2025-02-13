//
//  AppDelegate.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDependencies.shared.hotKeysManager.enableAll()

        NotificationCenter.default
            .publisher(for: .openMainWindow)
            .sink { [weak self] _ in
                self?.openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .store(in: &cancellables)

        #if DEBUG
        dismissWindow(id: "main")
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppDependencies.shared.pictureInPictureManager.restoreAllWindows()
    }
}
