//
//  SwipeManager.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//
//  Based on: https://github.com/MediosZ/SwipeAeroSpace

import AppKit

final class SwipeManager {
    typealias TouchId = ObjectIdentifier

    enum GestureState {
        case idle
        case inProgress
        case ended
    }

    static let shared = SwipeManager()

    private var swipeThreshold: Double { gesturesSettings.swipeThreshold }
    private var naturalDirection: Bool { gesturesSettings.naturalDirection }

    private var eventTap: CFMachPort?
    private var touchDistance: [TouchId: CGFloat] = [:]
    private var prevTouchPositions: [TouchId: NSPoint] = [:]
    private var lastTouchDate = Date.distantPast
    private var state: GestureState = .ended

    private lazy var gesturesSettings = AppDependencies.shared.gesturesSettings
    private lazy var workspaceManager = AppDependencies.shared.workspaceManager

    func start() {
        guard eventTap == nil else {
            return Logger.log("SwipeManager is already started")
        }

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: NSEvent.EventTypeMask.gesture.rawValue,
            callback: { proxy, type, cgEvent, userInfo in
                SwipeManager.shared.eventHandler(
                    proxy: proxy,
                    eventType: type,
                    cgEvent: cgEvent,
                    userInfo: userInfo
                )
            },
            userInfo: nil
        )

        guard let eventTap else {
            return Logger.log("SwipeManager couldn't create event tap")
        }

        Logger.log("SwipeManager started")

        let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            runLoopSource,
            CFRunLoopMode.commonModes
        )
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        guard let eventTap else { return }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFRunLoopRemoveSource(
            CFRunLoopGetCurrent(),
            CFMachPortCreateRunLoopSource(nil, eventTap, 0),
            CFRunLoopMode.commonModes
        )
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil

        Logger.log("SwipeManager stopped")
    }

    func eventHandler(
        proxy: CGEventTapProxy,
        eventType: CGEventType,
        cgEvent: CGEvent,
        userInfo: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? {
        if eventType.rawValue == NSEvent.EventType.gesture.rawValue,
           let nsEvent = NSEvent(cgEvent: cgEvent) {
            handleGesture(nsEvent)
        } else if eventType == .tapDisabledByUserInput || eventType == .tapDisabledByTimeout {
            Logger.log("SwipeManager tap disabled \(eventType)")
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }

        return Unmanaged.passUnretained(cgEvent)
    }

    private func handleGesture(_ nsEvent: NSEvent) {
        let touches = nsEvent.allTouches()
            .filter { !$0.isResting && $0.phase != .stationary }

        if touches.count == 0 || Date().timeIntervalSince(lastTouchDate) > 0.8 {
            state = .idle
        }

        if touches.count == 3 {
            if state == .idle {
                state = .inProgress
                touchDistance = [:]
                prevTouchPositions = [:]
            }
            if state == .inProgress {
                lastTouchDate = Date()
                handleSwipe(touches: touches)
            }
        }
    }

    private func handleSwipe(touches: Set<NSTouch>) {
        updateSwipeDistance(touches: touches)

        let swipes = touchDistance.values
        let allMovedRight = swipes.allSatisfy { $0 > 0 }
        let allMovedLeft = swipes.allSatisfy { $0 < 0 }

        guard swipes.count == 3,
              swipes.allSatisfy({ abs($0) > swipeThreshold / 5.0 }),
              abs(swipes.reduce(0.0, +)) >= swipeThreshold,
              allMovedLeft || allMovedRight else { return }

        let next = if naturalDirection {
            allMovedLeft
        } else {
            allMovedRight
        }

        state = .ended
        workspaceManager.activateWorkspace(next: next)
        Logger.log("3 fingers swipe ended, direction: \(next ? "next" : "prev")")
    }

    private func updateSwipeDistance(touches: Set<NSTouch>) {
        for touch in touches {
            let (distanceX, distanceY) = touchDistance(touch)

            if abs(distanceX) > abs(distanceY) {
                touchDistance[ObjectIdentifier(touch.identity), default: 0.0] += distanceX
            }

            prevTouchPositions[ObjectIdentifier(touch.identity)] = touch.normalizedPosition
        }
    }

    private func touchDistance(_ touch: NSTouch) -> (CGFloat, CGFloat) {
        guard let prevPosition = prevTouchPositions[ObjectIdentifier(touch.identity)] else {
            return (0.0, 0.0)
        }

        return (
            touch.normalizedPosition.x - prevPosition.x,
            touch.normalizedPosition.y - prevPosition.y
        )
    }
}
