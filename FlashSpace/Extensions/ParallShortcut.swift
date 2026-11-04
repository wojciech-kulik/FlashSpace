import Foundation

/// Parall metadata lives here so workspace matching does not depend on launcher plist keys.
enum ParallShortcut {
    static func launcher(id: String, info: [String: Any]) -> RunningAppIdentity.Launcher? {
        guard let target = info["ParallAppBundleId"] as? String, !target.isEmpty else { return nil }
        let home = (info["ParallHomeDirectory"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let arguments = words(in: info["ParallArguments"] as? String ?? "")
        let directory = profileDirectory(in: arguments)
        guard home != nil || directory != nil else { return nil }
        return .init(id: id, target: target, home: home, dataDirectory: directory)
    }

    static func profileDirectory(in arguments: [String]) -> String? {
        let option = "--user-data-dir"
        for (index, argument) in arguments.enumerated().reversed() {
            if argument.hasPrefix(option + "=") {
                let value = String(argument.dropFirst(option.count + 1))
                return value.isEmpty ? nil : value
            }
            if argument == option {
                let next = index + 1
                guard next < arguments.count, !arguments[next].isEmpty,
                      !arguments[next].hasPrefix("--") else { return nil }
                return arguments[next]
            }
        }
        return nil
    }

    /// Split Parall's quoted argument string without invoking a shell or expanding variables.
    private static func words(in arguments: String) -> [String] {
        var result: [String] = []
        var word = ""
        var quote: Character?
        var escaped = false
        var started = false
        for character in arguments {
            if escaped {
                word.append(character)
                escaped = false
            } else if character == "\\" && quote != "'" {
                escaped = true
                started = true
            } else if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    word.append(character)
                }
            } else if character == "'" || character == "\"" {
                quote = character
                started = true
            } else if character.isWhitespace {
                if started { result.append(word) }
                word = ""
                started = false
            } else {
                word.append(character)
                started = true
            }
        }
        guard quote == nil, !escaped else { return [] }
        if started { result.append(word) }
        return result
    }
}
