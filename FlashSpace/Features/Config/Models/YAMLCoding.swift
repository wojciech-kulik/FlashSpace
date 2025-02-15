//
//  YAMLCoding.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import Yams

extension YAMLEncoder: ConfigEncoder {
    func encode(_ value: some Encodable) throws -> Data {
        let yaml: String = try encode(value)
        return yaml.data(using: .utf8) ?? Data()
    }
}

extension YAMLDecoder: ConfigDecoder {}
