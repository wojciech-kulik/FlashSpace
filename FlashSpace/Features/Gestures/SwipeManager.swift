//
//  SwipeManager.swift
//
//  Created by Wojciech Kulik on 22/03/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//
//  Based on: https://github.com/MediosZ/SwipeAeroSpace

import AppKit
import Combine

final class SwipeManager {
    typealias TouchId = ObjectIdentifier

    enum Constants {
        static let minFingerCount = 3
        static let maxFingerCount = 4
    }

    enum GestureState {
        case idle
        case inProgress
        case ended
    }

    static let shared = SwipeManager()

    private var swipeThreshold: Double { gesturesSettings.swipeThreshold }

    private var eventTap: CFMachPort?
    private var xTouchDistance: [TouchId: CGFloat] = [:]
    private var yTouchDistance: [TouchId: CGFloat] = [:]
    private var prevTouchPositions: [TouchId: NSPoint] = [:]
    private var lastTouchDate = Date.distantPast
    private var state: GestureState = .ended
    private var systemWakeUpObserver: AnyCancellable?

    private lazy var gesturesSettings = AppDependencies.shared.gesturesSettings
    private lazy var workspaceSettings = AppDependencies.shared.workspaceSettings
    private lazy var workspaceManager = AppDependencies.shared.workspaceManager
    private lazy var workspaceRepository = AppDependencies.shared.workspaceRepository
    private lazy var focusManager = AppDependencies.shared.focusManager

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

        observeSystemWakeUp()
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

        systemWakeUpObserver?.cancel()
        systemWakeUpObserver = nil

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

        guard touches.count >= Constants.minFingerCount,
              gesturesSettings.isHorizontalSwipeSet || gesturesSettings.isVerticalSwipeSet
        else { return }

        if state == .idle {
            state = .inProgress
            xTouchDistance = [:]
            yTouchDistance = [:]
            prevTouchPositions = [:]
        }
        if state == .inProgress {
            lastTouchDate = Date()
            handleSwipe(touches: touches)
        }
    }

    private func handleSwipe(touches: Set<NSTouch>) {
        updateSwipeDistance(touches: touches)
        handleHorizontalSwipe()
        handleVerticalSwipe()
    }

    private func handleHorizontalSwipe() {
        guard state == .inProgress else { return }
        guard gesturesSettings.isHorizontalSwipeSet else { return }

        let swipes = xTouchDistance.values
        let allMovedRight = swipes.allSatisfy { $0 > 0 }
        let allMovedLeft = swipes.allSatisfy { $0 < 0 }
        let minFingerContribution = swipeThreshold / (CGFloat(swipes.count) + 2.0)

        guard (Constants.minFingerCount...Constants.maxFingerCount).contains(swipes.count),
              swipes.allSatisfy({ abs($0) > minFingerContribution }),
              abs(swipes.reduce(0.0, +)) >= swipeThreshold,
              allMovedLeft || allMovedRight else { return }

        let action = if allMovedRight {
            swipes.count == 3 ? gesturesSettings.swipeRight3FingerAction : gesturesSettings.swipeRight4FingerAction
        } else if allMovedLeft {
            swipes.count == 3 ? gesturesSettings.swipeLeft3FingerAction : gesturesSettings.swipeLeft4FingerAction
        } else {
            GestureAction.none
        }

        state = .ended
        callAction(action)
        Logger.log("Horizontal swipe detected")
    }

    private func handleVerticalSwipe() {
        guard state == .inProgress else { return }
        guard gesturesSettings.isVerticalSwipeSet else { return }

        let swipes = yTouchDistance.values
        let allMovedUp = swipes.allSatisfy { $0 > 0 }
        let allMovedDown = swipes.allSatisfy { $0 < 0 }
        let minFingerContribution = swipeThreshold / (CGFloat(swipes.count) + 2.0)

        guard (Constants.minFingerCount...Constants.maxFingerCount).contains(swipes.count),
              swipes.allSatisfy({ abs($0) > minFingerContribution }),
              abs(swipes.reduce(0.0, +)) >= swipeThreshold,
              allMovedUp || allMovedDown else { return }

        let action = if allMovedUp {
            swipes.count == 3 ? gesturesSettings.swipeUp3FingerAction : gesturesSettings.swipeUp4FingerAction
        } else if allMovedDown {
            swipes.count == 3 ? gesturesSettings.swipeDown3FingerAction : gesturesSettings.swipeDown4FingerAction
        } else {
            GestureAction.none
        }

        state = .ended
        callAction(action)
        Logger.log("Vertical swipe detected")
    }

    private func updateSwipeDistance(touches: Set<NSTouch>) {
        for touch in touches {
            let (distanceX, distanceY) = touchDistance(touch)

            if abs(distanceX) > abs(distanceY) {
                xTouchDistance[ObjectIdentifier(touch.identity), default: 0.0] += distanceX
            } else {
                yTouchDistance[ObjectIdentifier(touch.identity), default: 0.0] += distanceY
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

    // swiftlint:disable:next cyclomatic_complexity
    private func callAction(_ action: GestureAction) {
        let skipEmpty = workspaceSettings.skipEmptyWorkspacesOnSwitch
        let loop = workspaceSettings.loopWorkspaces

        switch action {
        case .none: break
        case .toggleSpaceControl: SpaceControl.toggle()
        case .showSpaceControl: SpaceControl.show()
        case .hideSpaceControl: SpaceControl.hide()
        case .nextWorkspace: workspaceManager.activateWorkspace(next: true, skipEmpty: skipEmpty, loop: loop)
        case .previousWorkspace: workspaceManager.activateWorkspace(next: false, skipEmpty: skipEmpty, loop: loop)
        case .mostRecentWorkspace: workspaceManager.activateRecentWorkspace()
        case .focusLeft: focusManager.focusLeft()
        case .focusRight: focusManager.focusRight()
        case .focusUp: focusManager.focusUp()
        case .focusDown: focusManager.focusDown()
        case .focusNextApp: focusManager.nextWorkspaceApp()
        case .focusPreviousApp: focusManager.previousWorkspaceApp()
        case .focusNextWindow: focusManager.nextWorkspaceWindow()
        case .focusPreviousWindow: focusManager.previousWorkspaceWindow()
        case .activateWorkspace(let workspaceName):
            if let workspace = workspaceRepository.workspaces.first(where: { $0.name == workspaceName }) {
                workspaceManager.activateWorkspace(workspace, setFocus: true)
            }
        }
    }
}

extension SwipeManager {
    func restartAppIfNeeded() {
        guard gesturesSettings.restartAppOnWakeUp else { return }

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", Bundle.main.bundlePath]
        task.launch()

        NSApp.terminate(self)
        exit(0)
    }

    private func observeSystemWakeUp() {
        systemWakeUpObserver = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in self?.restartAppIfNeeded() }
    }
}
