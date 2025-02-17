//
//  SocketClient.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import Network

final class SocketClient {
    static let shared = SocketClient()

    private let socketPath = "/tmp/flashspace.socket"
    private var buffer = Data()
    private let jsonEncoder = JSONEncoder()

    private init() {}

    func sendCommand(_ command: CommandRequest) {
        let connection = NWConnection(to: .unix(path: socketPath), using: .tcp)
        connection.start(queue: .main)

        let messageData = command.encodeSocketData()
        connection.send(content: messageData, completion: .contentProcessed { error in
            if let error {
                connection.cancel()
                FlashSpaceCLI.exit(withError: CommandError.connectionError(error))
            }

            self.receiveData(connection: connection)
        })
    }

    private func receiveData(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10000) { data, _, isComplete, error in
            if let error {
                connection.cancel()
                FlashSpaceCLI.exit(withError: CommandError.connectionError(error))
            }

            if let data { self.buffer.append(data) }

            // Check if the message is complete or EOF is reached
            guard isComplete || data?.last == 0 else {
                return self.receiveData(connection: connection)
            }

            if self.buffer.isEmpty {
                connection.cancel()
                FlashSpaceCLI.exit(withError: CommandError.emptyResponse)
            }

            if let response = try? self.buffer.decodeSocketData(CommandResponse.self) {
                self.handleResponse(response, connection: connection)
            } else {
                FlashSpaceCLI.exit(withError: CommandError.operationFailed("Could not decode the response"))
            }
        }
    }

    private func handleResponse(_ response: CommandResponse, connection: NWConnection) {
        if response.success {
            response.message.flatMap { print($0) }
            connection.cancel()
            FlashSpaceCLI.exit()
        } else {
            connection.cancel()
            FlashSpaceCLI.exit(withError: CommandError.operationFailed(response.error ?? "Operation Failed"))
        }
    }
}
