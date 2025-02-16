//
//  SettingsProtocol.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine

protocol SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> { get }

    func load(from appSettings: AppSettings)
    func update(_ appSettings: inout AppSettings)
}
