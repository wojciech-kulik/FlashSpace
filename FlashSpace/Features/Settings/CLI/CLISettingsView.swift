//
//  CLISettingsView.swift
//
//  Created by Wojciech Kulik on 18/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct CLISettingsView: View {
    @State var isInstalled = false
    @State var isRunning = false

    var body: some View {
        Form {
            Section("Status") {
                HStack {
                    if isRunning {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("FlashSpace CLI Status")
                        Spacer()
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)

                        Text("FlashSpace CLI Status")
                        Spacer()
                        Button("Restart") {
                            AppDependencies.shared.cliServer.restart()
                            isRunning = AppDependencies.shared.cliServer.isRunning
                        }
                    }
                }

                HStack {
                    if isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("FlashSpace CLI Installation")
                        Spacer()
                        Button("Uninstall FlashSpace CLI") {
                            CLI.uninstall()
                            isInstalled = CLI.isInstalled
                        }
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("FlashSpace CLI Installation")
                        Spacer()
                        Button("Install FlashSpace CLI") {
                            CLI.install()
                            isInstalled = CLI.isInstalled
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text(
                        """
                        Tool will be installed in /usr/local/bin/flashspace.

                        You can also access it directly from the app bundle at:
                        """
                    )
                    Text(CLI.cliPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(CLI.cliPath)
                }
                .foregroundColor(.secondary)
                .font(.callout)
            }

            Section {
                Text("Run `flashspace --help` in the terminal to see the available commands.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .onAppear {
            isInstalled = CLI.isInstalled
            isRunning = AppDependencies.shared.cliServer.isRunning
        }
        .formStyle(.grouped)
        .navigationTitle("CLI")
    }
}
