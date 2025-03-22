//
//  WorkspaceTransitionManager.swift
//
//  Created for FlashSpace
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

final class WorkspaceTransitionManager {
    static let shared = WorkspaceTransitionManager()

    private var transitionWindow: NSWindow?
    private var isAnimating = false

    // Configuration
    var enableTransitionEffects = true
    var transitionDuration: TimeInterval = 0.3

    func performTransition(direction: TransitionDirection, onComplete: @escaping () -> ()) {
        guard enableTransitionEffects, !isAnimating else {
            onComplete()
            return
        }

        isAnimating = true

        let contentView = NSHostingView(
            rootView: WorkspaceTransitionView(direction: direction)
        )

        // Create a full-screen window that overlays everything
        guard let mainScreen = NSScreen.main else {
            isAnimating = false
            onComplete()
            return
        }

        let window = NSWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        transitionWindow = window

        // Set up the content view
        window.contentView = contentView
        window.orderFrontRegardless()

        // Animate the transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Execute the workspace change
            onComplete()

            // Animate the transition out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = self.transitionDuration
                    window.animator().alphaValue = 0.0
                }, completionHandler: {
                    window.orderOut(nil)
                    self.transitionWindow = nil
                    self.isAnimating = false
                })
            }
        }
    }

    enum TransitionDirection {
        case left
        case right
    }
}

struct WorkspaceTransitionView: View {
    let direction: WorkspaceTransitionManager.TransitionDirection

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
