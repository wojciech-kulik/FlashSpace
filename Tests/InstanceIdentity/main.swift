import AppKit
import Darwin

func buffer(arguments: [String], environment: [String]) -> [UInt8] {
    let argc = UInt32(arguments.count)
    var bytes = (0..<4).map { UInt8((argc >> ($0 * 8)) & 255) }
    bytes += Array("/Applications/Cursor.app/Contents/MacOS/Cursor".utf8) + [0, 0, 0]
    for value in arguments + environment { bytes += Array(value.utf8) + [0] }
    return bytes
}
let home = "/Users/test/Library/Application Support/Parall/Cursor (Work)/home"
assert(RunningAppIdentity.home(in: buffer(arguments: ["Cursor", "HOME=argument"], environment: ["OTHER=value", "HOME=\(home)"])) == home)
assert(RunningAppIdentity.home(in: buffer(arguments: ["Cursor"], environment: ["OTHER=value"])) == nil)
assert(RunningAppIdentity.home(in: []) == nil)
assert(RunningAppIdentity.home(in: [1, 0, 0, 0]) == nil)
assert(RunningAppIdentity.processHome(pid: getpid()) == ProcessInfo.processInfo.environment["HOME"])
assert(RunningAppIdentity.processHome(pid: -1) == nil)
let launcher = RunningAppIdentity.Launcher(id: "work", target: "cursor", home: home, dataDirectory: "/profile with spaces/data")
assert(RunningAppIdentity.launcherIdentifier(target: "cursor", home: "/normal", arguments: ["--user-data-dir=/profile with spaces/data"], launchers: [launcher]) == "work")
assert(RunningAppIdentity.launcherIdentifier(target: "cursor", home: home, arguments: [], launchers: [launcher]) == nil)
assert(RunningAppIdentity.launcherIdentifier(target: "cursor", home: "/normal", arguments: ["--user-data-dir", "/profile with spaces/data"], launchers: [launcher]) == "work")
assert(RunningAppIdentity.launcherIdentifier(target: "other", home: home, arguments: [], launchers: [launcher]) == nil)
assert(RunningAppIdentity.launcherIdentifier(target: "cursor", home: home, arguments: ["--user-data-dir=/profile with spaces/data"], launchers: [launcher, launcher]) == nil)
let homeLauncher = RunningAppIdentity.Launcher(id: "home", target: "cursor", home: home, dataDirectory: nil)
assert(RunningAppIdentity.launcherIdentifier(target: "cursor", home: home, arguments: [], launchers: [homeLauncher]) == "home")
let argv = ["Cursor", "--user-data-dir=/path with spaces"]
assert(RunningAppIdentity.arguments(in: buffer(arguments: argv, environment: ["HOME=/normal"])) == argv)
for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == "com.todesktop.230313mzl4w4u92" {
    print("Cursor PID \(app.processIdentifier): \(app.workspaceBundleIdentifier ?? "unknown")")
}
print("Instance identity checks passed")
