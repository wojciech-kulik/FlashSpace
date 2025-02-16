//
//  AcknowledgementsSettingsView.swift
//
//  Created by Wojciech Kulik on 26/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AcknowledgementsSettingsView: View {
    @State private var selectedDependency: String? = "xnth97/SymbolPicker"
    @State private var dependencies = [
        "xnth97/SymbolPicker",
        "Kentzo/ShortcutRecorder",
        "LebJe/TOMLKit",
        "jpsim/Yams",
        "SwiftFormat",
        "SwiftLint"
    ]

    var body: some View {
        VStack(spacing: 0.0) {
            List(
                dependencies,
                id: \.self,
                selection: $selectedDependency
            ) { dependency in
                Text(dependency)
            }.frame(height: 130)

            ScrollView([.vertical, .horizontal]) {
                VStack {
                    Group {
                        switch selectedDependency {
                        case "xnth97/SymbolPicker":
                            Text(Licenses.symbolPicker)
                        case "Kentzo/ShortcutRecorder":
                            Text(Licenses.shortcutRecorder)
                        case "LebJe/TOMLKit":
                            Text(Licenses.tomlKit)
                        case "jpsim/Yams":
                            Text(Licenses.yams)
                        case "SwiftFormat":
                            Text(Licenses.swiftFormat)
                        case "SwiftLint":
                            Text(Licenses.swiftLint)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(minHeight: 330, alignment: .top)
                    .textSelection(.enabled)
                    .padding()
                }
            }
        }
        .navigationTitle("Acknowledgements")
    }
}
