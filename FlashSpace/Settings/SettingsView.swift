//
//  SettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = "General"

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn), sidebar: {
            sideMenu
                .frame(width: 200)
                .navigationSplitViewColumnWidth(200.0)
        }, detail: {
            details
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        })
        .frame(width: 780, height: 490)
    }

    private var sideMenu: some View {
        VStack {
            List(selection: $selectedTab) {
                Label("General", systemImage: "gearshape")
                    .tag("General")
                Label("Focus Manager", systemImage: "macwindow.on.rectangle")
                    .tag("Focus")
                Label("Workspaces", systemImage: "square.stack.3d.up")
                    .tag("Workspaces")
                Label("Integrations", systemImage: "link")
                    .tag("Integrations")
                Label("Profiles", systemImage: "person.2")
                    .tag("Profiles")
                Label("Acknowledgements", systemImage: "info.circle")
                    .tag("Acknowledgements")
            }
            .toolbar(removing: .sidebarToggle)
            .listStyle(.sidebar)

            Spacer()

            Text("FlashSpace v\(AppConstants.version)")
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }

    @ViewBuilder
    private var details: some View {
        switch selectedTab {
        case "General":
            GeneralSettingsView()
        case "Focus":
            FocusSettingsView()
        case "Workspaces":
            WorkspacesSettingsView()
        case "Integrations":
            IntegrationsSettingsView()
        case "Profiles":
            ProfilesSettingsView()
        case "Acknowledgements":
            AcknowledgementsSettingsView()
        default:
            EmptyView()
        }
    }
}
