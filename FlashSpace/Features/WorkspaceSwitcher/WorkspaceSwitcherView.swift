//
//  WorkspaceSwitcherView.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspaceSwitcherView: View {
    @ObservedObject var viewModel: WorkspaceSwitcherViewModel

    var body: some View {
        if #available(macOS 26.0, *) {
            content
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 44, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1.0)
                )
        }
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(viewModel.workspaces.enumerated()), id: \.element.id) { index, workspace in
                        if viewModel.showScreenshots {
                            switcherItemWithScreenshot(
                                workspace,
                                isSelected: index == viewModel.selectedIndex,
                                itemSize: viewModel.itemSize
                            )
                            .id(index)
                        } else {
                            switcherItem(
                                workspace,
                                isSelected: index == viewModel.selectedIndex,
                                itemSize: viewModel.itemSize
                            )
                            .id(index)
                        }
                    }
                }
                .padding(.horizontal, 36)
            }
            .onChange(of: viewModel.selectedIndex) { _, newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(viewModel.selectedIndex, anchor: .center)
            }
        }
        .frame(width: viewModel.containerSize.width, height: viewModel.containerSize.height)
    }

    private func switcherItem(
        _ workspace: WorkspaceSwitcherItem,
        isSelected: Bool,
        itemSize: CGSize
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: workspace.symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.workspaceIcon)
                .frame(width: itemSize.width * 0.5, height: itemSize.height * 0.5)
                .frame(width: itemSize.width)

            Text(workspace.name)
                .font(.title2)
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(width: itemSize.width, height: itemSize.height)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 0.8)
                .fill(Color.white.opacity(isSelected ? 0.14 : 0.0))
                .padding(1)
        )
    }

    private func switcherItemWithScreenshot(
        _ workspace: WorkspaceSwitcherItem,
        isSelected: Bool,
        itemSize: CGSize
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: workspace.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.workspaceIcon)

                Text(workspace.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Group {
                if let image = workspace.screenshotData.flatMap(NSImage.init(data:)) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Text("Preview Not Available")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .hidden(!viewModel.showScreenshots)
        }
        .padding(12)
        .frame(width: itemSize.width, height: itemSize.height)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 0.8)
                .fill(Color.white.opacity(isSelected ? 0.14 : 0.0))
                .padding(1)
        )
    }
}
