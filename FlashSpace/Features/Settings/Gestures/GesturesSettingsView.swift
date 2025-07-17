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
            Section {
                Toggle("Enable Swipe Gestures", isOn: $settings.enableSwipeGestures)
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
                Text("Remember to disable system gestures in System Preferences > Trackpad > More Gestures.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(
                    "Keeping \"Swipe between full-screen apps\" enabled prevents from detecting swipe gesture as " +
                        "a scroll action. However, you must keep only one macOS Space to avoid switching."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section("Horizontal Swipes") {
                Picker("3-Finger Left Swipe", selection: $settings.swipeLeft3FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("3-Finger Right Swipe", selection: $settings.swipeRight3FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("4-Finger Left Swipe", selection: $settings.swipeLeft4FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("4-Finger Right Swipe", selection: $settings.swipeRight4FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
            }
            .disabled(!settings.enableSwipeGestures)
            .opacity(settings.enableSwipeGestures ? 1 : 0.5)

            Section("Vertical Swipes") {
                Picker("3-Finger Up Swipe", selection: $settings.swipeUp3FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("3-Finger Down Swipe", selection: $settings.swipeDown3FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("4-Finger Up Swipe", selection: $settings.swipeUp4FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
                Picker("4-Finger Down Swipe", selection: $settings.swipeDown4FingerAction) {
                    ForEach(GestureAction.allCases) { action in
                        Text(action.description).tag(action)
                    }
                }
            }
            .disabled(!settings.enableSwipeGestures)
            .opacity(settings.enableSwipeGestures ? 1 : 0.5)

            Section("System") {
                Toggle("Restart App On Wake Up", isOn: $settings.restartAppOnWakeUp)
                Text(
                    "Restarts the app when your Mac wakes up from sleep. This can help with gesture recognition issues after waking."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .disabled(!settings.enableSwipeGestures)
            .opacity(settings.enableSwipeGestures ? 1 : 0.5)
        }
        .formStyle(.grouped)
        .navigationTitle("Gestures")
    }
}
