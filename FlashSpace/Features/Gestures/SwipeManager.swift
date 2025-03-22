//
//  SwipeManager.swift
//
//  Original source code: https://github.com/MediosZ/SwipeAeroSpace
//  Refactored and modified by Wojciech Kulik on 21/03/2025.

// MIT License
//
// Copyright (c) 2025 Tricster
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AppKit

final class SwipeManager {
    enum GestureState {
        case began
        case changed
        case ended
        case cancelled
    }

    static let shared = SwipeManager()

    private var enableWorkspaceTransition: Bool { workspaceSettings.enableWorkspaceTransition }
    private var naturalDirection: Bool { workspaceSettings.naturalDirection }
    private var swipeFingerCount: Int { workspaceSettings.swipeFingerCount.rawValue }
    private var swipeThreshold: Double { workspaceSettings.swipeThreshold }

    private var eventTap: CFMachPort?
    private var horizontalSwipeSum: Float = 0
    private var prevTouchPositions: [String: NSPoint] = [:]
    private var state: GestureState = .ended

    private lazy var workspaceSettings = AppDependencies.shared.workspaceSettings
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

        guard !touches.isEmpty else { return }

        let touchesCount = touches.allSatisfy { $0.phase == .ended } ? 0 : touches.count

        if touchesCount == 0 {
            gestureFinished()
        } else if touchesCount == swipeFingerCount {
            state = .began
            horizontalSwipeSum += horizontalSwipeDistance(touches: touches)
        }
    }

    private func gestureFinished() {
        guard state == .began else { return }

        state = .ended

        guard abs(horizontalSwipeSum) >= Float(swipeThreshold) else { return }

        let next = if naturalDirection {
            horizontalSwipeSum < 0
        } else {
            horizontalSwipeSum >= 0
        }

        Logger.log("\(swipeFingerCount) fingers swipe finished, direction: \(next ? "next" : "prev")")
        horizontalSwipeSum = 0.0
        prevTouchPositions.removeAll()

        let direction: WorkspaceTransitionManager.TransitionDirection = next ? .right : .left
        WorkspaceTransitionManager.shared.enableTransitionEffects = enableWorkspaceTransition
        WorkspaceTransitionManager.shared.performTransition(direction: direction) {
            self.workspaceManager.activateWorkspace(next: next)
        }
    }

    private func horizontalSwipeDistance(touches: Set<NSTouch>) -> Float {
        var allRight = true
        var allLeft = true
        var sumX = Float(0)
        var sumY = Float(0)

        for touch in touches {
            let (distanceX, distanceY) = touchDistance(touch)
            allRight = allRight && distanceX >= 0
            allLeft = allLeft && distanceX <= 0
            sumX += distanceX
            sumY += distanceY

            if touch.phase == .ended {
                prevTouchPositions.removeValue(forKey: "\(touch.identity)")
            } else {
                prevTouchPositions["\(touch.identity)"] = touch.normalizedPosition
            }
        }

        // All fingers should move in the same direction.
        guard allRight || allLeft else { return 0.0 }

        // Only horizontal swipes are interesting.
        guard abs(sumX) > abs(sumY) else { return 0.0 }

        return sumX
    }

    private func touchDistance(_ touch: NSTouch) -> (Float, Float) {
        guard let prevPosition = prevTouchPositions["\(touch.identity)"] else { return (0, 0) }

        return (
            Float(touch.normalizedPosition.x - prevPosition.x),
            Float(touch.normalizedPosition.y - prevPosition.y)
        )
    }
}
