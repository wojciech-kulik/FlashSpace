//
//  GestureAction.swift
//
//  Created by Wojciech Kulik on 30/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

enum GestureAction {
    case none
    case toggleSpaceControl
    case showSpaceControl
    case hideSpaceControl
    case nextWorkspace
    case previousWorkspace
    case mostRecentWorkspace
    case focusLeft
    case focusRight
    case focusUp
    case focusDown
    case focusNextApp
    case focusPreviousApp
    case focusNextWindow
    case focusPreviousWindow
    case activateWorkspace(String)
}

extension GestureAction: CaseIterable, Equatable, Hashable, Identifiable {
    var id: String { description }

    var description: String {
        switch self {
        case .none: return "None"
        case .toggleSpaceControl: return "Toggle Space Control"
        case .showSpaceControl: return "Show Space Control"
        case .hideSpaceControl: return "Hide Space Control"
        case .nextWorkspace: return "Next Workspace"
        case .previousWorkspace: return "Previous Workspace"
        case .mostRecentWorkspace: return "Most Recent Workspace"
        case .focusLeft: return "Focus Left"
        case .focusRight: return "Focus Right"
        case .focusUp: return "Focus Up"
        case .focusDown: return "Focus Down"
        case .focusNextApp: return "Focus Next App"
        case .focusPreviousApp: return "Focus Previous App"
        case .focusNextWindow: return "Focus Next Window"
        case .focusPreviousWindow: return "Focus Previous Window"
        case .activateWorkspace(let workspaceName):
            return "Activate Workspace: \(workspaceName)"
        }
    }

    static var allCases: [GestureAction] {
        let workspaces = AppDependencies.shared.workspaceRepository.workspaces
        return allCasesWithoutWorkspaces + workspaces.map { .activateWorkspace($0.name) }
    }

    static var allCasesWithoutWorkspaces: [GestureAction] {
        [
            .none,
            .toggleSpaceControl,
            .showSpaceControl,
            .hideSpaceControl,
            .nextWorkspace,
            .previousWorkspace,
            .mostRecentWorkspace,
            .focusLeft,
            .focusRight,
            .focusUp,
            .focusDown,
            .focusNextApp,
            .focusPreviousApp,
            .focusNextWindow,
            .focusPreviousWindow
        ]
    }
}

extension GestureAction: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        if value.hasPrefix("activateWorkspace:") {
            let workspaceName = String(value.dropFirst("activateWorkspace:".count))
            self = .activateWorkspace(workspaceName)
        } else if let action = GestureAction.allCasesWithoutWorkspaces.first(where: { $0.normalizedDescription == value }) {
            self = action
        } else {
            self = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(normalizedDescription)
    }

    private var normalizedDescription: String {
        if case .activateWorkspace(let workspaceName) = self {
            return "activateWorkspace:\(workspaceName)"
        }

        let result = String(description.first?.lowercased() ?? "") + description.dropFirst()
        return result.replacingOccurrences(of: " ", with: "")
    }
}
