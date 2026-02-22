//
//  SettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var navigationManager = SettingsNavigationManager.shared

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
        .frame(width: 780, height: 550)
        .onDisappear {
            navigationManager.selectedTab = "General"
        }
    }

    private var sideMenu: some View {
        VStack {
            List(selection: $navigationManager.selectedTab) {
                Label("General", systemImage: "gearshape")
                    .tag("General")
                Label("Menu Bar", systemImage: "contextualmenu.and.cursorarrow")
                    .tag("MenuBar")
                Label("Gestures", systemImage: "hand.draw")
                    .tag("Gestures")
                Label("Workspaces", systemImage: "square.stack.3d.up")
                    .tag("Workspaces")
                Label("Picture-in-Picture", systemImage: "pip")
                    .tag("Picture-in-Picture")
                Label("Floating Apps", systemImage: "macwindow.on.rectangle")
                    .tag("FloatingApps")
                Label("Focus Manager", systemImage: "rectangle.righthalf.filled")
                    .tag("Focus")
                Label("Space Control", systemImage: "rectangle.split.2x2")
                    .tag("SpaceControl")
                Label("Profiles", systemImage: "person.2")
                    .tag("Profiles")
                Label("Integrations", systemImage: "link")
                    .tag("Integrations")
                Label("Configuration File", systemImage: "doc.text")
                    .tag("Configuration")
                Label("CLI", systemImage: "apple.terminal")
                    .tag("CLI")
                Label("Acknowledgements", systemImage: "info.circle")
                    .tag("Acknowledgements")
                Label("Donate", systemImage: "heart")
                    .tag("Donate")
                Label("About", systemImage: "person")
                    .tag("About")
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
        switch navigationManager.selectedTab {
        case "General":
            GeneralSettingsView()
        case "MenuBar":
            MenuBarSettingsView()
        case "Focus":
            FocusSettingsView()
        case "Gestures":
            GesturesSettingsView()
        case "Workspaces":
            WorkspacesSettingsView()
        case "Picture-in-Picture":
            PictureInPictureSettingsView()
        case "FloatingApps":
            FloatingAppsSettingsView()
        case "SpaceControl":
            SpaceControlSettingsView()
        case "Integrations":
            IntegrationsSettingsView()
        case "Profiles":
            ProfilesSettingsView()
        case "Configuration":
            ConfigurationFileSettingsView()
        case "CLI":
            CLISettingsView()
        case "Acknowledgements":
            AcknowledgementsSettingsView()
        case "Donate":
            DonateSettingsView()
        case "About":
            AboutSettingsView()
        default:
            EmptyView()
        }
    }
}
