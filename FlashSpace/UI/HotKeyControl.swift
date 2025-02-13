//
//  HotKeyControl.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import ShortcutRecorder
import SwiftUI

struct HotKeyControl: NSViewRepresentable {
    @Binding var shortcut: HotKeyShortcut?

    func makeNSView(context: Context) -> RecorderControl {
        let control = RecorderControl(frame: .zero)
        control.delegate = context.coordinator
        control.objectValue = shortcut.flatMap { $0.toShortcut() }

        return control
    }

    func updateNSView(_ nsView: RecorderControl, context: Context) {
        context.coordinator.parent = self
        nsView.objectValue = shortcut.flatMap { $0.toShortcut() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, RecorderControlDelegate {
        var parent: HotKeyControl

        private let hotKeysManager = AppDependencies.shared.hotKeysManager

        init(parent: HotKeyControl) {
            self.parent = parent
        }

        func recorderControlDidBeginRecording(_ aControl: RecorderControl) {
            hotKeysManager.disableAll()
        }

        func recorderControl(_ aControl: RecorderControl, canRecord aShortcut: Shortcut) -> Bool {
            true
        }

        func recorderControlDidEndRecording(_ aControl: RecorderControl) {
            guard let shortcut = aControl.objectValue else {
                parent.shortcut = nil
                hotKeysManager.enableAll()
                return
            }

            parent.shortcut = .init(
                keyCode: shortcut.keyCode.rawValue,
                modifiers: shortcut.modifierFlags.rawValue
            )
            hotKeysManager.enableAll()
        }
    }
}
