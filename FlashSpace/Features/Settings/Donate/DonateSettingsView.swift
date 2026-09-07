//
//  DonateSettingsView.swift
//
//  Created by Wojciech Kulik on 12/02/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct DonateSettingsView: View {
    @State private var copiedBTC = false
    @State private var copiedETH = false

    var body: some View {
        Form {
            Section("GitHub Sponsors") {
                HStack {
                    Text("Support development on GitHub Sponsors")
                    Spacer()
                    Button("Open GitHub Sponsors") {
                        openUrl("https://github.com/sponsors/wojciech-kulik")
                    }
                }
            }

            Section("Buy Me a Coffee") {
                HStack {
                    Text("Support with a coffee")
                    Spacer()
                    Button("Open Buy Me a Coffee") {
                        openUrl("https://buymeacoffee.com/wojciechkulik")
                    }
                }
            }

            Section("Buy Snippety") {
                HStack {
                    Text("Support by buying Snippety")
                    Spacer()
                    Button("Snippety.app") {
                        openUrl("https://snippety.app")
                    }
                }
            }
        }
        .buttonStyle(.accessoryBarAction)
        .formStyle(.grouped)
        .navigationTitle("Donate")
    }

    private func openUrl(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}
