//
//  SocketDataSerialization.swift
//
//  Created by Wojciech Kulik on 17/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension Data {
    func decodeSocketData<T: Decodable>(_ type: T.Type) throws -> T {
        var data = self
        data.removeLast()
        return try JSONDecoder().decode(T.self, from: data)
    }
}

extension Encodable {
    func encodeSocketData() -> Data? {
        var result = try? JSONEncoder().encode(self)
        result?.append(0)
        return result
    }
}
