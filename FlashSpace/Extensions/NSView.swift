//
//  NSView.swift
//
//  Created by Wojciech Kulik on 11/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSView {
    func addVisualEffect(material: NSVisualEffectView.Material, border: Bool = false) -> NSView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active

        if border {
            visualEffectView.wantsLayer = true
            visualEffectView.layer?.cornerRadius = 24
            visualEffectView.layer?.borderWidth = 0.8
            visualEffectView.layer?.borderColor = NSColor.darkGray.cgColor
            visualEffectView.layer?.masksToBounds = true
        }

        visualEffectView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])

        return visualEffectView
    }
}
