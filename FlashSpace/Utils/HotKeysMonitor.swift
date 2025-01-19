//
//  HotKeysMonitor.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

protocol HotKeysMonitorProtocol: AnyObject {
    var actions: [ShortcutAction] { get }

    func addAction(_ anAction: ShortcutAction, forKeyEvent aKeyEvent: KeyEventType)
    func removeAction(_ anAction: ShortcutAction)
    func removeAllActions()
}

extension GlobalShortcutMonitor: HotKeysMonitorProtocol {}
