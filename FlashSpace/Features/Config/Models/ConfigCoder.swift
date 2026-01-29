//
//  ConfigCoder.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

protocol ConfigEncoder {
    func encode(_ value: some Encodable) throws -> Data
}

protocol ConfigDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
