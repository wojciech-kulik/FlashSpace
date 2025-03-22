//
//  GesturesSettingsView.swift
//
//  Created by Wojciech Kulik on 21/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct GesturesSettingsView: View {
    @StateObject private var settings = AppDependencies.shared.gesturesSettings

    var body: some View {
        Form {
            Section("Swipe Gestures") {
                Toggle("Enable Swipe Gestures", isOn: $settings.enableSwipeGesture)

                Group {
                    Picker("Finger Count", selection: $settings.swipeFingerCount) {
                        ForEach(GesturesSettings.FingerCount.allCases) { fingerCount in
                            Text(fingerCount.description).tag(fingerCount)
                        }
                    }

                    Toggle("Natural Direction", isOn: $settings.swipeNaturalDirection)

                    HStack {
                        Text("Activation Threshold")
                        Spacer()
                        Text("\(settings.swipeThreshold, specifier: "%.2f")")
                        Stepper(
                            "",
                            value: $settings.swipeThreshold,
                            in: 0.05...0.7,
                            step: 0.05
                        ).labelsHidden()
                    }
                }
                .disabled(!settings.enableSwipeGesture)
                .opacity(settings.enableSwipeGesture ? 1 : 0.5)

                Text("This gesture allows to switch between next and previous workspace.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Gestures")
    }
}
