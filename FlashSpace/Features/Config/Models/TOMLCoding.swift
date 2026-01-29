//
//  TOMLCoding.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import TOMLKit

extension TOMLEncoder: ConfigEncoder {
    func encode(_ value: some Encodable) throws -> Data {
        let toml: String = try encode(value)
        return toml.data(using: .utf8) ?? Data()
    }
}

extension TOMLDecoder: ConfigDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let toml = String(data: data, encoding: .utf8) ?? ""
        return try decode(T.self, from: toml)
    }
}
