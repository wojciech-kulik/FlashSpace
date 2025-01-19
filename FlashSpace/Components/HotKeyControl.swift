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
    // @Binding var shortcut: Shortcut
    let workspace: Workspace?

    func makeNSView(context: Context) -> RecorderControl {
        let control = RecorderControl(frame: .zero)
        control.delegate = context.coordinator
        return control
    }

    func updateNSView(_ nsView: RecorderControl, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, RecorderControlDelegate {
        var parent: HotKeyControl

        init(parent: HotKeyControl) {
            self.parent = parent
        }

        func recorderControlDidBeginRecording(_ aControl: RecorderControl) {
            hotKeysManager.disableAll()
        }

        func recorderControl(_ aControl: RecorderControl, canRecord aShortcut: Shortcut) -> Bool {
            parent.workspace != nil
        }

        func recorderControlDidEndRecording(_ aControl: RecorderControl) {
            guard let workspace = parent.workspace,
                  let shortcut = aControl.objectValue else { return }

            hotKeysManager.update(
                workspaceId: workspace.id,
                shortcut: .init(
                    keyCode: shortcut.keyCode.rawValue,
                    modifiers: shortcut.modifierFlags.rawValue
                )
            )
            hotKeysManager.enableAll()
        }
    }
}
