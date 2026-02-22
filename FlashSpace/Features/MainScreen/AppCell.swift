//
//  AppCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AppCell: View {
    let workspaceId: WorkspaceID
    let app: MacApp

    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        HStack {
            if let iconPath = app.iconPath, let image = NSImage(byReferencingFile: iconPath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Text(app.name)
                .foregroundColor(app.bundleIdentifier.isEmpty ? .errorRed : .primary)

            if viewModel.isEditingApps {
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.isAutoOpenEnabled(for: app) },
                    set: { viewModel.setAutoOpen($0, for: app, in: workspaceId) }
                ))
            }
        }
        .draggable(MacAppWithWorkspace(app: app, workspaceId: workspaceId))
    }
}
