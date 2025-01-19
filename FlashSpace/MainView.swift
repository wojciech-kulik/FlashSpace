//
//  MainView.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import AppKit
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Workspaces:")
                    List(
                        viewModel.workspaces,
                        id: \.self,
                        selection: $viewModel.selectedWorkspace
                    ) { workspace in
                        Text(workspace.name)
                    }
                    .frame(width: 200, height: 400)
                }

                VStack(alignment: .leading) {
                    Text("Assigned Apps:")
                    List(
                        viewModel.workspaceApps ?? [],
                        id: \.self
                    ) { app in
                        Text(app)
                    }
                    .frame(width: 200, height: 400)
                }

                VStack(alignment: .leading, spacing: 0.0) {
                    Text("Workspace Configuration:")
                        .padding(.bottom, 16.0)
                        .fixedSize()

                    Text("Name:")
                    TextField("Name", text: $viewModel.workspaceName).padding(.bottom)
                    Text("Display:")
                    TextField("Display", text: $viewModel.workspaceDisplay).padding(.bottom)
                    Text("Shortcut:")
                    TextField("Shortcut", text: $viewModel.workspaceShortcut).padding(.bottom)
                    Spacer()
                }
            }
        }
        .padding()
        .fixedSize()
    }
}

#Preview {
    MainView()
}
