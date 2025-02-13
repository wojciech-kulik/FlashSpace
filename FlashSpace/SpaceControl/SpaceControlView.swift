//
//  SpaceControlView.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SpaceControlView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = SpaceControlViewModel()

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: viewModel.numberOfColumns)
        let width = (NSScreen.main?.frame.width ?? 1200) / CGFloat(viewModel.numberOfColumns) - 70.0
        let height = (NSScreen.main?.frame.height ?? 800) / CGFloat(viewModel.numberOfRows) - 120.0

        LazyVGrid(columns: columns, spacing: viewModel.numberOfRows == 2 ? 90.0 : 60.0) {
            ForEach(viewModel.workspaces, id: \.index) { workspace in
                VStack(alignment: .leading, spacing: 16.0) {
                    workspaceName(workspace)

                    Group {
                        if let image = workspace.screenshotData.flatMap(NSImage.init(data:)) {
                            workspacePreview(image: image, width: width, height: height)
                        } else {
                            workspacePlaceholder(width: width, height: height)
                        }
                    }
                    .overlay(alignment: .topTrailing) { workspaceNumber(workspace.index + 1) }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18.0)
                            .stroke(
                                workspace.isActive
                                    ? !viewModel.onlyCurrentDisplay && workspace.originalWorkspace.isOnTheCurrentScreen
                                        ? Color.positive
                                        : Color.teal
                                    : Color.black.opacity(0.8),
                                lineWidth: 3.0
                            )
                    )
                    .compositingGroup()
                    .shadow(
                        color: .black.opacity(workspace.screenshotData != nil ? 0.8 : 0.0),
                        radius: 20.0,
                        x: 0.0,
                        y: 0.0
                    )
                }
                .onTapGesture { viewModel.onWorkspaceTap(workspace) }
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func workspacePreview(image: NSImage, width: CGFloat, height: CGFloat) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: width, maxHeight: height)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }

    private func workspacePlaceholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18.0)
            .fill(Color.black.opacity(0.5))
            .frame(maxWidth: width, maxHeight: height)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                Text("Preview Not Available")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
    }

    private func workspaceName(_ workspace: SpaceControlWorkspace) -> some View {
        HStack(spacing: 16.0) {
            Image(systemName: workspace.symbol)
                .resizable()
                .scaledToFit()
                .frame(height: 17.0)
                .foregroundColor(colorScheme == .dark ? .workspaceIcon : .primary)

            Text(workspace.name)
                .foregroundColor(.primary)
                .font(.title2)
        }
        .fontWeight(.semibold)
        .lineLimit(1)
        .compositingGroup()
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.8 : 0.25),
            radius: 4.0,
            x: 0.0,
            y: 0.0
        )
    }

    private func workspaceNumber(_ number: Int) -> some View {
        Text("\(number)")
            .foregroundColor(.white)
            .font(.title3)
            .frame(width: 40.0)
            .padding(.vertical, 8.0)
            .background(Color.black)
            .cornerRadius(18.0, corners: [.topRight])
            .cornerRadius(8.0, corners: [.bottomLeft])
    }
}
