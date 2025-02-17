//
//  CommandExecutor.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

protocol CommandExecutor {
    func execute(command: CommandRequest) -> CommandResponse?
}
