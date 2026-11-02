import AppKit
import Darwin

/// Resolve Parall's target process back to its launcher identity. Never persist PIDs.
enum RunningAppIdentity {
    struct Launcher {
        let id: String
        let target: String
        let home: String
        let dataDirectory: String?
    }

    private static var copies: [String: String] = [:]
    private static var launchers: [Launcher] = []
    private static var refreshed = Date.distantPast
    private static var cache: [pid_t: (Date, String)] = [:]

    static func identifier(for app: NSRunningApplication) -> String? {
        guard let original = app.bundleIdentifier else { return nil }
        let now = Date()
        if now.timeIntervalSince(refreshed) > 5 {
            launchers = discoverLaunchers()
            refreshed = now
            cache.removeAll()
        }
        guard launchers.contains(where: { $0.target == original }) else { return app.bundleURL.flatMap { copies[$0.standardizedFileURL.path] } ?? original }
        if let entry = cache[app.processIdentifier], now.timeIntervalSince(entry.0) < 1 { return entry.1 }
        let bytes = processBytes(pid: app.processIdentifier) ?? []
        let home = home(in: bytes)
        let arguments = arguments(in: bytes)
        let selected = launcherIdentifier(target: original, home: home, arguments: arguments, launchers: launchers)
        let id = selected ?? app.bundleURL.flatMap { copies[$0.standardizedFileURL.path] } ?? original
        cache[app.processIdentifier] = (now, id)
        return id
    }

    static func launcherIdentifier(target: String, home: String?, arguments: [String], launchers: [Launcher]) -> String? {
        let matches = launchers.filter { launcher in
            guard launcher.target == target else { return false }
            if let data = launcher.dataDirectory {
                return arguments.contains("--user-data-dir=\(data)") ||
                    zip(arguments, arguments.dropFirst()).contains { $0 == "--user-data-dir" && $1 == data }
            }
            return launcher.home == home
        }
        return matches.count == 1 ? matches[0].id : nil
    }

    private static func discoverLaunchers() -> [Launcher] {
        let roots = [URL(fileURLWithPath: "/Applications"), FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        var bundles: [String: [URL]] = [:]
        let result = roots.flatMap { root -> [Launcher] in
            guard let entries = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
            var result: [Launcher] = []
            for case let url as URL in entries where url.pathExtension == "app" {
                entries.skipDescendants()
                guard let bundle = Bundle(url: url), let info = bundle.infoDictionary,
                      let id = bundle.bundleIdentifier else { continue }
                bundles[id, default: []].append(url)
                guard
                      let target = info["ParallAppBundleId"] as? String,
                      let home = info["ParallHomeDirectory"] as? String, !home.isEmpty else { continue }
                let arguments = info["ParallArguments"] as? String ?? ""
                let storage = info["ParallDataStorage"] as? String
                let data = storage.map { $0 + "/data" }
                let usesData = data.map { arguments.contains("--user-data-dir=\"\($0)\"") || arguments == "--user-data-dir=\($0)" } ?? false
                result.append(Launcher(id: id, target: target, home: home, dataDirectory: usesData ? data : nil))
            }
            return result
        }
        copies.removeAll()
        for (_, urls) in bundles where urls.count > 1 {
            let sorted = urls.sorted { lhs, rhs in
                func canonical(_ url: URL) -> Bool {
                    let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                    return url.deletingPathExtension().lastPathComponent == name
                }
                if canonical(lhs) != canonical(rhs) { return canonical(lhs) }
                return lhs.path < rhs.path
            }
            for url in sorted.dropFirst() {
                copies[url.standardizedFileURL.path] = "flashspace.copy:" + url.standardizedFileURL.path
            }
        }
        return result
    }

    static func identifier(for url: URL) -> String? {
        if Date().timeIntervalSince(refreshed) > 5 {
            launchers = discoverLaunchers()
            refreshed = Date()
            cache.removeAll()
        }
        return copies[url.standardizedFileURL.path] ?? Bundle(url: url)?.bundleIdentifier
    }

    static func applicationURL(for identifier: String) -> URL? {
        if identifier.hasPrefix("flashspace.copy:") {
            return URL(fileURLWithPath: String(identifier.dropFirst("flashspace.copy:".count)))
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier)
    }

    /// KERN_PROCARGS2 is NUL-delimited; paths containing spaces remain intact.
    /// Read only HOME from the environment, and do not retain or log other values.
    static func processHome(pid: pid_t) -> String? {
        processBytes(pid: pid).flatMap { home(in: $0) }
    }

    private static func processBytes(pid: pid_t) -> [UInt8]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 4 else { return nil }
        var bytes = [UInt8](repeating: 0, count: size)
        let status = bytes.withUnsafeMutableBytes { sysctl(&mib, UInt32(mib.count), $0.baseAddress, &size, nil, 0) }
        guard status == 0 else { return nil }
        return Array(bytes.prefix(size))
    }

    static func arguments(in bytes: [UInt8]) -> [String] {
        guard bytes.count >= 4 else { return [] }
        let argc = bytes.prefix(4).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << ($1.offset * 8) }
        var index = 4
        while index < bytes.count && bytes[index] != 0 { index += 1 }
        while index < bytes.count && bytes[index] == 0 { index += 1 }
        var result: [String] = []
        for _ in 0..<argc {
            guard index < bytes.count else { return [] }
            let start = index
            while index < bytes.count && bytes[index] != 0 { index += 1 }
            guard let value = String(bytes: bytes[start..<index], encoding: .utf8) else { return [] }
            result.append(value)
            index += 1
        }
        return result
    }

    static func home(in bytes: [UInt8]) -> String? {
        guard bytes.count >= 4 else { return nil }
        let argc = bytes.prefix(4).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << ($1.offset * 8) }
        guard argc > 0 else { return nil }
        var index = 4
        func skipString() { while index < bytes.count && bytes[index] != 0 { index += 1 }; index += 1 }
        skipString() // executable path
        while index < bytes.count && bytes[index] == 0 { index += 1 }
        for _ in 0..<argc { guard index < bytes.count else { return nil }; skipString() }
        while index < bytes.count {
            let start = index
            skipString()
            guard let value = String(bytes: bytes[start..<min(index - 1, bytes.count)], encoding: .utf8) else { continue }
            if value.hasPrefix("HOME=") { return String(value.dropFirst(5)) }
        }
        return nil
    }
}

extension NSRunningApplication {
    var workspaceBundleIdentifier: String? { RunningAppIdentity.identifier(for: self) }
}
