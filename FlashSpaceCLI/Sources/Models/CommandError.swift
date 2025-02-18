//
//  CommandError.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum CommandError: Error, LocalizedError {
    case timeout
    case connectionError(Error)
    case emptyResponse
    case couldNotEncode(Error)
    case operationFailed(String)
    case missingArgument
    case other

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Timeout. Please check if FlashSpace is running."
        case .connectionError(let error):
            return "Connection error. Please check if FlashSpace is running.\n\(error)"
        case .emptyResponse:
            return "Empty response. Please check if FlashSpace is running."
        case .couldNotEncode(let error):
            return "Could not encode the message. Please try again.\n\(error)"
        case .operationFailed(let message):
            return message
        case .missingArgument:
            return "Missing argument(s). Please provide the required argument(s)."
        case .other:
            return ""
        }
    }
}
