//
//  ConfigCoder.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

protocol ConfigEncoder {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

protocol ConfigDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}
