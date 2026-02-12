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

    let btcAddress = "bc1qqs4ct2tje2xuu4e9y5tjkzardefckvw6rv4emh"
    let ethAddress = "0x9Fb744Fdcf6Be6ADb70d4D841deeAD779Ab6e6e2"

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

            Section("Bitcoin") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BTC Address")
                            .font(.headline)
                        Spacer()
                        Button(copiedBTC ? "Copied!" : "Copy Address") {
                            copyBTCAddress()
                        }
                        .disabled(copiedBTC)
                    }

                    Text(btcAddress)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Ethereum") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ETH Address")
                            .font(.headline)
                        Spacer()
                        Button(copiedETH ? "Copied!" : "Copy Address") {
                            copyETHAddress()
                        }
                        .disabled(copiedETH)
                    }

                    Text(ethAddress)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
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

    private func copyETHAddress() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ethAddress, forType: .string)

        copiedETH = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { copiedETH = false }
    }

    private func copyBTCAddress() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(btcAddress, forType: .string)

        copiedBTC = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { copiedBTC = false }
    }
}
