//
//  WorkspaceSwitcher.swift
//
//  Created by Wojciech Kulik on 05/03/2026.
//  Copyright © 2026 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

// swiftlint:disable:next type_body_length
enum WorkspaceSwitcher {
    // MARK: - Types

    enum NavigationDirection {
        case forward
        case backward

        var step: Int {
            switch self {
            case .forward: return 1
            case .backward: return -1
            }
        }
    }

    // MARK: - Constants

    private static let delayedShowDuration: TimeInterval = 0.1

    // MARK: - State

    private static var window: NSWindow?
    private static var viewModel: WorkspaceSwitcherViewModel?
    private static var focusedAppBeforeShow: NSRunningApplication?

    private static var isPendingShow = false
    private static var pendingShowTask: DispatchWorkItem?
    private static var lastRepeatTime: TimeInterval = 0

    private static var eventMonitors: [Any] = []

    // MARK: - Computed Properties

    static var isEnabled: Bool { settings.enableWorkspaceSwitcher }
    static var isVisible: Bool { window != nil || isPendingShow }

    private static var settings: WorkspaceSwitcherSettings {
        AppDependencies.shared.workspaceSwitcherSettings
    }

    private static var workspaceRepository: WorkspaceRepository {
        AppDependencies.shared.workspaceRepository
    }

    private static var hotKeysManager: HotKeysManager {
        AppDependencies.shared.hotKeysManager
    }

    private static var screenshotManager: WorkspaceScreenshotManager {
        AppDependencies.shared.workspaceScreenshotManager
    }

    // MARK: - Public API

    static func getHotKeys() -> [RecordedHotKey] {
        guard isEnabled, let baseHotKey = settings.showWorkspaceSwitcher else {
            return []
        }

        var hotKeys: [RecordedHotKey] = []

        // Register base hotkey (forward)
        hotKeys.append(RecordedHotKey(
            name: .workspaceSwitcher,
            hotKey: baseHotKey,
            action: { show(direction: .forward) }
        ))

        // Register backward hotkey (base + shift)
        if let backwardHotKey = createBackwardHotKey(from: baseHotKey) {
            hotKeys.append(RecordedHotKey(
                name: .workspaceSwitcherBackward,
                hotKey: backwardHotKey,
                action: { show(direction: .backward) }
            ))
        }

        return hotKeys
    }

    static func show(direction: NavigationDirection = .forward) {
        guard validateCanShow() else { return }

        if isVisible {
            cancelPendingShow()
            hide(activateSelection: false)
        }

        prepareToShow(direction: direction)
    }

    static func hide(activateSelection: Bool) {
        cancelPendingShow()

        // Quick switch: window not shown yet, activate immediately
        if isPendingShow, window == nil {
            performQuickSwitch(activateSelection: activateSelection)
            return
        }

        // Normal hide: fade out window if it exists
        guard window != nil else { return }
        hideAndCleanup(activateSelection: activateSelection)
    }

    static func cancel() {
        hide(activateSelection: false)
    }

    // MARK: - Preparation

    private static func prepareToShow(direction: NavigationDirection) {
        Task { @MainActor in
            if settings.workspaceSwitcherShowScreenshots,
               let activeWorkspace = AppDependencies.shared.workspaceManager.activeWorkspace[.current] {
                await screenshotManager.captureWorkspace(activeWorkspace, displayName: .current)
            }
        }

        let viewModel = WorkspaceSwitcherViewModel()
        Self.viewModel = viewModel
        viewModel.advanceSelection(step: direction.step)

        isPendingShow = true
        startEventMonitoring()
        scheduleDelayedShow()
    }

    private static func scheduleDelayedShow() {
        let task = DispatchWorkItem {
            guard isPendingShow else { return }
            isPendingShow = false
            showWindow()
        }

        pendingShowTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delayedShowDuration, execute: task)
    }

    private static func cancelPendingShow() {
        pendingShowTask?.cancel()
        pendingShowTask = nil
    }

    // MARK: - Window Management

    private static func showWindow() {
        guard let viewModel else { return }

        let window = createWindow(for: viewModel)
        Self.window = window
        focusedAppBeforeShow = NSWorkspace.shared.frontmostApplication

        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    private static func createWindow(for viewModel: WorkspaceSwitcherViewModel) -> WorkspaceSwitcherWindow {
        let contentView = NSHostingView(
            rootView: WorkspaceSwitcherView(viewModel: viewModel)
        )

        let contentRect = calculateWindowFrame(for: viewModel)

        let window = WorkspaceSwitcherWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureWindow(window, with: contentView)
        return window
    }

    private static func configureWindow(_ window: WorkspaceSwitcherWindow, with contentView: NSView) {
        window.level = .screenSaver
        window.delegate = window
        window.isOpaque = false
        window.backgroundColor = .clear

        if #available(macOS 26.0, *) {
            let effect = NSGlassEffectView()
            effect.appearance = .init(named: .darkAqua)
            effect.cornerRadius = 44
            effect.contentView = contentView
            effect.clipsToBounds = true
            window.contentView = effect
        } else {
            contentView.appearance = .init(named: .darkAqua)
            window.contentView = contentView
        }
    }

    private static func calculateWindowFrame(for viewModel: WorkspaceSwitcherViewModel) -> NSRect {
        let containerSize = viewModel.containerSize
        let screenCenterX = NSScreen.main?.frame.midX ?? 600
        let screenCenterY = NSScreen.main?.frame.midY ?? 600

        return NSRect(
            x: screenCenterX - containerSize.width / 2,
            y: screenCenterY - containerSize.height / 2,
            width: containerSize.width,
            height: containerSize.height
        )
    }

    // MARK: - Cleanup

    private static func performQuickSwitch(activateSelection: Bool) {
        isPendingShow = false
        stopEventMonitoring()

        if activateSelection {
            viewModel?.activateSelection()
        }

        viewModel = nil
    }

    private static func hideAndCleanup(activateSelection: Bool) {
        if activateSelection {
            viewModel?.activateSelection()
        } else {
            focusedAppBeforeShow?.activate()
        }

        stopEventMonitoring()

        focusedAppBeforeShow = nil
        window?.orderOut(nil)
        window = nil
        isPendingShow = false
        viewModel = nil
    }

    // MARK: - Event Monitoring

    private static func startEventMonitoring() {
        stopEventMonitoring()
        hotKeysManager.disableAll()

        let localKeyUpMonitor = createLocalKeyUpMonitor()
        let localKeyDownMonitor = createLocalKeyDownMonitor()
        let globalKeyUpMonitor = createGlobalKeyUpMonitor()
        let globalKeyDownMonitor = createGlobalKeyDownMonitor()

        [localKeyUpMonitor, localKeyDownMonitor, globalKeyUpMonitor, globalKeyDownMonitor]
            .compactMap { $0 }
            .forEach { eventMonitors.append($0) }
    }

    private static func stopEventMonitoring() {
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        eventMonitors.removeAll()
        hotKeysManager.enableAll()
    }

    private static func createGlobalKeyUpMonitor() -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .flagsChanged]) { event in
            if isModifierReleased(in: event) {
                hide(activateSelection: true)
            }
        }
    }

    private static func createLocalKeyUpMonitor() -> Any? {
        NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .flagsChanged]) { event in
            if isModifierReleased(in: event) {
                hide(activateSelection: true)
                return nil
            }
            return event
        }
    }

    private static func createLocalKeyDownMonitor() -> Any? {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard !event.isARepeat || (event.timestamp - lastRepeatTime) > 0.15 else { return event }

            if event.keyCode == switcherKeyCode() {
                lastRepeatTime = event.timestamp

                let step = event.modifierFlags.contains(.shift) ? -1 : 1
                viewModel?.advanceSelection(step: step)
                return nil
            }

            return event
        }
    }

    private static func createGlobalKeyDownMonitor() -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            guard !event.isARepeat else { return }

            if event.keyCode == switcherKeyCode() {
                let step = event.modifierFlags.contains(.shift) ? -1 : 1
                viewModel?.advanceSelection(step: step)
            }
        }
    }

    private static func isModifierReleased(in event: NSEvent) -> Bool {
        let requiredModifiers = extractRequiredModifiers()
        return !event.modifierFlags.contains(requiredModifiers)
    }

    // MARK: - Validation & Helpers

    private static func validateCanShow() -> Bool {
        let workspaces = workspaceRepository.workspaces
            .filter { !settings.workspaceSwitcherCurrentDisplayWorkspaces || $0.isOnTheCurrentScreen }
            .filter(\.displays.isNotEmpty)

        if workspaces.isEmpty {
            Alert.showOkAlert(
                title: "Workspace Switcher",
                message: "You need at least 1 workspace to use Workspace Switcher."
            )
            return false
        }

        return true
    }

    private static func extractRequiredModifiers() -> NSEvent.ModifierFlags {
        guard let modifiers = settings.showWorkspaceSwitcher?.value.split(separator: "+") else {
            return []
        }

        return modifiers
            .dropLast() // Drop the key itself, keep only modifiers
            .map { String($0) }
            .reduce(into: NSEvent.ModifierFlags()) { result, modifier in
                switch modifier {
                case "cmd": result.insert(.command)
                case "ctrl": result.insert(.control)
                case "opt": result.insert(.option)
                case "shift": result.insert(.shift)
                default: break
                }
            }
    }

    private static func switcherKeyCode() -> RawKeyCode? {
        guard let hotKey = settings.showWorkspaceSwitcher else { return nil }
        guard let keyString = hotKey.value.split(separator: "+").last else { return nil }
        return KeyCodesMap[String(keyString)] ?? KeyCodesMap["tab"]
    }

    private static func createBackwardHotKey(from baseHotKey: AppHotKey) -> AppHotKey? {
        let components = baseHotKey.value.split(separator: "+").map { String($0) }
        guard let key = components.last else { return nil }

        var modifiers = components.dropLast().filter { $0.lowercased() != "shift" }

        modifiers.append("shift")

        let backwardValue = (modifiers + [key]).joined(separator: "+")
        return AppHotKey(value: backwardValue)
    }
}
