//
//  AboutSettingsView.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section("FlashSpace") {
                HStack {
                    Text("Version \(AppConstants.version)")
                    Spacer()
                    Button("GitHub") { openGitHub("wojciech-kulik/FlashSpace") }
                    Button("Check for Updates") { UpdatesManager.shared.checkForUpdates() }
                }
            }

            Section("Author") {
                HStack {
                    Text("Wojciech Kulik (@wojciech-kulik)")
                    Spacer()
                    Button("GitHub") { openGitHub("wojciech-kulik") }
                    Button("X.com") { openUrl("https://x.com/kulik_wojciech") }
                    Button("snippety.app") { openUrl("https://snippety.app") }
                }
            }

            Section("Contributors") {
                HStack {
                    Text("Kwangmin Bae / Shirou (@PangMo5)")
                    Spacer()
                    Button("GitHub") { openGitHub("PangMo5") }
                }
                HStack {
                    Text("Sergio (@sergiopatino)")
                    Spacer()
                    Button("GitHub") { openGitHub("sergiopatino") }
                }
                HStack {
                    Text("Moritz Brödel (@brodmo)")
                    Spacer()
                    Button("GitHub") { openGitHub("brodmo") }
                }
            }
        }
        .buttonStyle(.accessoryBarAction)
        .formStyle(.grouped)
        .navigationTitle("About")
    }

    private func openGitHub(_ login: String) {
        openUrl("https://github.com/\(login)")
    }

    private func openUrl(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}
