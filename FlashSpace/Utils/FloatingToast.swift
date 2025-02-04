//
//  FloatingToast.swift
//
//  Created by Wojciech Kulik on 28/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

weak var floatingToastWindow: NSWindow?

// swiftlint:disable:next function_body_length
func showFloatingToast(icon: String, message: String, textColor: Color) {
    guard AppDependencies.shared.settingsRepository.showFloatingNotifications else { return }

    if let window = floatingToastWindow {
        window.orderOut(nil)
        floatingToastWindow = nil
    }

    let contentView = NSHostingView(
        rootView: FloatingPanelView(
            icon: icon,
            message: message,
            textColor: textColor
        )
    )
    let size = contentView.fittingSize

    let window = NSWindow(
        contentRect: NSRect(
            x: (NSScreen.main?.frame.midX ?? 200.0) - size.width / 2.0,
            y: (NSScreen.main?.frame.minY ?? 0.0) + (NSScreen.main?.frame.height ?? 0.0) * 0.07,
            width: size.width,
            height: size.height
        ),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    floatingToastWindow = window

    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = .sidebar
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.wantsLayer = true
    visualEffectView.layer?.cornerRadius = 24
    visualEffectView.layer?.borderWidth = 0.8
    visualEffectView.layer?.borderColor = NSColor.darkGray.cgColor
    visualEffectView.layer?.masksToBounds = true

    visualEffectView.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
        contentView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
        contentView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
        contentView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
        contentView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
    ])

    window.contentView = visualEffectView
    window.orderFrontRegardless()

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }
}

struct FloatingPanelView: View {
    let icon: String
    let message: String
    let textColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 26)

            Text(message)
                .font(.title)
        }
        .opacity(0.9)
        .padding()
        .padding(.horizontal)
        .fontWeight(.semibold)
        .foregroundStyle(textColor)
    }
}
