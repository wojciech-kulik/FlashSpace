//
//  ConfigSerializer.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import TOMLKit
import Yams

enum ConfigSerializer {
    static let configDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashspace")

    private(set) static var format: ConfigFormat = detectFormat()

    static func serialize(filename: String, _ value: some Encodable) throws {
        let url = getUrl(for: filename)
        let data = try encoder.encode(value)
        try? url.createIntermediateDirectories()
        try data.write(to: url)
    }

    static func deserialize<T: Decodable>(_ type: T.Type, filename: String) throws -> T? {
        let url = getUrl(for: filename)

        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)

            return try decoder.decode(type, from: data)
        } catch {
            Logger.log("Failed to deserialize \(filename): \(error)")
            throw error
        }
    }

    static func convert(to: ConfigFormat) throws {
        guard format != to else { return }

        let settingsUrl = getUrl(for: "settings", ext: format.rawValue)
        let profilesUrl = getUrl(for: "profiles", ext: format.rawValue)
        let timestamp = Int(Date().timeIntervalSince1970)

        try? FileManager.default.moveItem(
            at: settingsUrl,
            to: configDirectory.appendingPathComponent("settings-backup-\(timestamp).\(format.rawValue)")
        )
        try? FileManager.default.moveItem(
            at: profilesUrl,
            to: configDirectory.appendingPathComponent("profiles-backup-\(timestamp).\(format.rawValue)")
        )

        format = to
        AppDependencies.shared.settingsRepository.saveToDisk()
        AppDependencies.shared.profilesRepository.saveToDisk()

        Logger.log("Converted config format to \(to.displayName)")
    }
}

private extension ConfigSerializer {
    static var encoder: ConfigEncoder {
        switch format {
        case .json: return jsonEncoder
        case .toml: return tomlEncoder
        case .yaml: return yamlEncoder
        }
    }

    static var decoder: ConfigDecoder {
        switch format {
        case .json: return jsonDecoder
        case .toml: return tomlDecoder
        case .yaml: return yamlDecoder
        }
    }

    static let jsonDecoder = JSONDecoder()
    static let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .withoutEscapingSlashes,
            .sortedKeys
        ]
        return encoder
    }()

    static let tomlDecoder = TOMLDecoder()
    static let tomlEncoder = TOMLEncoder()
    static let yamlEncoder = YAMLEncoder()
    static let yamlDecoder = YAMLDecoder()

    static func getUrl(for filename: String, ext: String? = nil) -> URL {
        configDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension(ext ?? ConfigSerializer.format.extensionName)
    }

    static func detectFormat() -> ConfigFormat {
        for format in ConfigFormat.allCases {
            let url = getUrl(for: "profiles", ext: format.rawValue)
            if FileManager.default.fileExists(atPath: url.path) {
                Logger.log("Detected config format \(format.displayName) at \(url.path)")
                return format
            }
        }

        return .json
    }
}
