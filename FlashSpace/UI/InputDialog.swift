//
//  InputDialog.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct InputDialog: View {
    let title: String
    var placeholder = "Type here..."

    @Binding var userInput: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(title)
                .font(.headline)

            TextField(placeholder, text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8.0)
                .onSubmit { isPresented = false }

            HStack {
                Spacer()
                Button("Cancel") {
                    userInput = ""
                    isPresented = false
                }
                Button("OK") { isPresented = false }
            }
        }
        .padding()
        .frame(width: 300, height: 110)
        .onKeyPress(.escape) {
            userInput = ""
            isPresented = false
            return .handled
        }
    }
}
