//
//  CLIServer.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import Network

final class CLIServer {
    var isRunning: Bool {
        switch listener?.state ?? .cancelled {
        case .cancelled, .failed: return false
        default: return true
        }
    }

    private var listener: NWListener?
    private let socketPath = "/tmp/flashspace.socket"
    private let executors: [CommandExecutor] = [
        ProfileCommands(),
        WorkspaceCommands(),
        AppCommands(),
        FocusCommands(),
        SpaceControlCommands(),
        ListCommands(),
        GetCommands()
    ]

    init() { startServer() }

    func restart() {
        listener?.cancel()
        startServer()
    }

    private func startServer() {
        try? FileManager.default.removeItem(atPath: socketPath)

        do {
            let params = NWParameters(tls: nil, tcp: .init())
            params.allowLocalEndpointReuse = true
            params.requiredLocalEndpoint = .unix(path: socketPath)

            listener = try NWListener(using: params)
            listener?.newConnectionHandler = handleNewConnection
            listener?.start(queue: .global(qos: .userInitiated))
            Logger.log("🟢 Server started at \(socketPath)")
        } catch {
            Logger.log("❌ Failed to start server: \(error)")
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        Logger.log("✅ New client connected")

        let buffer = BufferWrapper()
        receiveData(connection: connection, buffer: buffer)
    }

    private func receiveData(connection: NWConnection, buffer: BufferWrapper) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10000) { data, _, isComplete, error in
            if let error {
                connection.cancel()
                return Logger.log("❌ Receive error: \(error)")
            }

            if let data { buffer.data.append(data) }

            // Check if complete or EOF at the end
            guard isComplete || data?.last == 0 else {
                return self.receiveData(connection: connection, buffer: buffer)
            }

            guard !buffer.data.isEmpty else {
                connection.cancel()
                return Logger.log("❌ Received empty data")
            }

            do {
                let command = try buffer.data.decodeSocketData(CommandRequest.self)
                DispatchQueue.main.async {
                    self.handleCommand(command, connection: connection)
                }
            } catch {
                connection.cancel()
                Logger.log("❌ Failed to decode command: \(error)")
            }
        }
    }

    private func handleCommand(_ command: CommandRequest, connection: NWConnection) {
        var result: CommandResponse?
        for executor in executors {
            result = executor.execute(command: command)
            if result != nil { break }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let response = result?.encodeSocketData() {
                connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
            } else {
                connection.cancel()
                Logger.log("❌ Failed to encode response")
            }
        }
    }
}
