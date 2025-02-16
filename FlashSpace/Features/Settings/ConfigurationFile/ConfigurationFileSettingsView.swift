//
//  ConfigurationFileSettingsView.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

struct ConfigurationFileSettingsView: View {
    @State var configFormat: ConfigFormat = ConfigSerializer.format

    var body: some View {
        Form {
            Section {
                Picker("Format", selection: $configFormat) {
                    ForEach(ConfigFormat.allCases, id: \.rawValue) { format in
                        Text(format.displayName).tag(format)
                    }
                }.onChange(of: configFormat) { _, newFormat in
                    try? ConfigSerializer.convert(to: newFormat)
                }

                HStack {
                    Text("Location: \(ConfigSerializer.configDirectory.path)")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Spacer()
                    Button("Reveal") {
                        NSWorkspace.shared.open(ConfigSerializer.configDirectory)
                    }
                }

                Text(
                    "If you manually edit the configuration file, make sure to restart FlashSpace.\n" +
                        "Custom formatting, order, comments, etc. will be overwritten if you change something in the app."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration File")
    }
}
