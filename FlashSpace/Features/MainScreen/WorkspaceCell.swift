//
//  WorkspaceCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceCell: View {
    @State var isTargeted = false
    @Binding var selectedApps: Set<MacApp>

    let workspaceManager: WorkspaceManager = AppDependencies.shared.workspaceManager
    let workspaceRepository: WorkspaceRepository = AppDependencies.shared.workspaceRepository

    let workspace: Workspace

    var body: some View {
        HStack {
            Image(systemName: workspace.symbolIconName ?? .defaultIconSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(Color.workspaceIcon)

            Text(workspace.name)
                .lineLimit(1)
                .foregroundColor(
                    isTargeted || workspace.apps.contains(where: \.bundleIdentifier.isEmpty)
                        ? .errorRed
                        : .primary
                )
            Spacer()
        }
        .contentShape(Rectangle())
        .dropDestination(for: MacAppWithWorkspace.self) { apps, _ in
            guard let sourceWorkspaceId = apps.first?.workspaceId else { return false }

            workspaceRepository.moveApps(
                apps.map(\.app),
                from: sourceWorkspaceId,
                to: workspace.id
            )
            selectedApps = []

            workspaceManager.activateWorkspaceIfActive(sourceWorkspaceId)
            workspaceManager.activateWorkspaceIfActive(workspace.id)

            return true
        } isTargeted: {
            isTargeted = $0
        }
    }
}
