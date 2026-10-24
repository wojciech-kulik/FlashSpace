//
//  HotKeyControl.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import KeyboardShortcuts
import SwiftUI

struct HotKeyControl: NSViewRepresentable {
    static var isListeningForChanges = true

    let name: KeyboardShortcuts.Name

    @Binding var shortcut: AppHotKey?

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        KeyboardShortcuts.RecorderCocoa(for: name)
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {
        nsView.shortcutName = name
        nsView.bezelStyle = .squareBezel
        nsView.validateShortcut = { shortcut in
            let allHotKeys = AppDependencies.shared.hotKeysManager.allHotKeys

            if let conflict = allHotKeys.first(where: { $0.hotKey.toShortcut() == shortcut })?.scope {
                return .disallow(reason: "This shortcut is already assigned within the \(conflict) scope.")
            }

            return .allow
        }
        context.coordinator.parent = self
        context.coordinator.observe()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator {
        var parent: HotKeyControl

        private let hotKeysManager = AppDependencies.shared.hotKeysManager
        private var cancellables = Set<AnyCancellable>()

        init(parent: HotKeyControl) {
            self.parent = parent
            observe()
        }

        func observe() {
            cancellables.removeAll()

            NotificationCenter.default
                .publisher(for: .shortcutByNameDidChange)
                .filter { _ in HotKeyControl.isListeningForChanges }
                .sink { [weak self] notification in
                    Task { await self?.handleNotification(notification) }
                }
                .store(in: &cancellables)
        }

        @MainActor
        private func handleNotification(_ notification: Notification) {
            guard let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
                  name == parent.name else { return }

            if let shortcut = KeyboardShortcuts.getShortcut(for: name), let key = shortcut.key {
                parent.shortcut = .init(
                    keyCode: UInt16(key.rawValue),
                    modifiers: shortcut.modifiers.rawValue
                )
            } else {
                parent.shortcut = nil
            }
        }
    }
}
