//
//  SpaceControlView.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SpaceControlView: View {
    let cornerRadius: CGFloat = 12.0

    @StateObject var viewModel = SpaceControlViewModel()

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: viewModel.numberOfColumns)

        ZStack {
            LazyVGrid(columns: columns, spacing: viewModel.numberOfRows == 2 ? 90.0 : 60.0) {
                ForEach(viewModel.workspaces, id: \.index) { workspace in
                    VStack(alignment: .leading, spacing: 16.0) {
                        workspaceName(workspace)

                        Group {
                            if let image = workspace.screenshotData.flatMap(NSImage.init(data:)) {
                                workspacePreview(image: image)
                            } else {
                                workspacePlaceholder
                            }
                        }
                        .overlay(alignment: .topTrailing) { workspaceNumber(workspace.index + 1) }
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    workspace.isActive
                                        ? workspace.originalWorkspace.isOnTheCurrentScreen
                                            ? Color.positive
                                            : Color.teal
                                        : Color.black.opacity(0.5),
                                    lineWidth: 1.0
                                )
                        )
                        .compositingGroup()
                        .shadow(
                            color: .black.opacity(workspace.screenshotData != nil ? 0.35 : 0.0),
                            radius: 4.0,
                            x: 0.0,
                            y: 1.0
                        )
                    }
                    .onTapGesture { viewModel.onWorkspaceTap(workspace) }
                }
            }
            .hidden(!viewModel.isVisible)
            .transition(.scale(scale: 1.1, anchor: .center))
        }
        .animation(.smooth(duration: 0.3), value: viewModel.isVisible)
        .onAppear { viewModel.isVisible = true }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if let wallpaperImage = viewModel.wallpaperImage {
                Image(nsImage: wallpaperImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 32.0, opaque: true)
                    .saturation(1.25)
            }
        }
        .ignoresSafeArea()
    }

    private var workspacePlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.black.opacity(0.4))
            .frame(width: viewModel.tileSize.width, height: viewModel.tileSize.height)
            .overlay {
                Text("Preview Not Available")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
    }

    private func workspacePreview(image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: viewModel.tileSize.width, height: viewModel.tileSize.height)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func workspaceName(_ workspace: SpaceControlWorkspace) -> some View {
        HStack(spacing: 16.0) {
            Image(systemName: workspace.symbol)
                .resizable()
                .scaledToFit()
                .frame(height: 15.0)
                .foregroundColor(.workspaceIcon)
                .colorScheme(.dark)

            Text(workspace.name)
                .foregroundColor(.white)
                .font(.title3)
        }
        .fontWeight(.semibold)
        .lineLimit(1)
        .compositingGroup()
        .shadow(
            color: .black.opacity(0.5),
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
            .cornerRadius(cornerRadius, corners: [.topRight])
            .cornerRadius(8.0, corners: [.bottomLeft])
    }
}
