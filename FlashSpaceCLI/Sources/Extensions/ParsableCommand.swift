//
//  ParsableCommand.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ArgumentParser
import Foundation

extension ParsableCommand {
    func sendCommand(_ command: CommandRequest) {
        SocketClient.shared.sendCommand(command)
    }

    func fallbackToHelp() {
        print(Self.helpMessage(for: Self.self))
        Self.exit(withError: CommandError.other)
    }

    func runWithTimeout() {
        RunLoop.current.run(until: Date().addingTimeInterval(5.0))
        Self.exit(withError: CommandError.timeout)
    }
}
