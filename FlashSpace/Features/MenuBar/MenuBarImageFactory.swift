//
//  MenuBarImageFactory.swift
//
//  Created by Wojciech Kulik on 26/10/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit

enum MenuBarImageFactory {
    // swiftlint:disable:next function_parameter_count
    static func make(
        symbolName: String?,
        title: String?,
        bold: Bool,
        boldIcon: Bool,
        monospaced: Bool,
        spacing: CGFloat,
        minWidth: CGFloat
    ) -> NSImage {
        let fontSize = NSFont.menuBarFont(ofSize: 0).pointSize
        let weight: NSFont.Weight = bold ? .medium : .regular
        let font = monospaced
            ? NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight)
            : bold ? NSFont.systemFont(ofSize: fontSize, weight: weight) : NSFont.menuBarFont(ofSize: fontSize)

        var symbol: NSImage?
        if let symbolName {
            let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: boldIcon ? .bold : .regular)
            symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        }

        let measureAttrs: [NSAttributedString.Key: Any] = [.font: font]
        let titleSize = title.map { ($0 as NSString).size(withAttributes: measureAttrs) } ?? .zero
        let symbolSize = symbol?.size ?? .zero

        let gap: CGFloat = (symbol != nil && title != nil) ? spacing : 0
        let contentWidth = symbolSize.width + gap + titleSize.width
        let width = max(contentWidth, minWidth)
        let height = max(symbolSize.height, titleSize.height, 22)

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let color = NSColor.labelColor

            var x = (rect.width - contentWidth) / 2

            if let symbol {
                let y = (rect.height - symbolSize.height) / 2
                let tinted = NSImage(size: symbolSize, flipped: false) { r in
                    symbol.draw(in: r)
                    color.set()
                    r.fill(using: .sourceAtop)
                    return true
                }
                tinted.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height))
                x += symbolSize.width + gap
            }

            if let title {
                let y = (rect.height - titleSize.height) / 2
                (title as NSString).draw(
                    at: NSPoint(x: x, y: y),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
            }
            return true
        }

        image.isTemplate = false
        return image
    }
}
