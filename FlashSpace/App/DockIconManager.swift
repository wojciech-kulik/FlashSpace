import AppKit

final class DockIconManager {
    static let shared = DockIconManager()

    private static let windowIds: Set<String> = ["main", "settings"]

    private var observer: (any NSObjectProtocol)?

    private init() {}

    func startObserving() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow, Self.isAppWindow(window) else { return }

            self?.hideDockIconIfNeeded(closing: window)
        }
    }

    func showDockIcon() {
        guard NSApp.activationPolicy() != .regular else { return }

        NSApp.setActivationPolicy(.regular)
    }

    private func hideDockIconIfNeeded(closing closedWindow: NSWindow) {
        let hasVisibleWindows = NSApp.windows
            .filter { $0 !== closedWindow }
            .filter(\.isVisible)
            .contains(where: Self.isAppWindow)

        guard !hasVisibleWindows, NSApp.activationPolicy() != .accessory else { return }

        NSApp.setActivationPolicy(.accessory)
    }

    private static func isAppWindow(_ window: NSWindow) -> Bool {
        guard let id = window.identifier?.rawValue else { return false }

        return windowIds.contains(id)
    }
}
