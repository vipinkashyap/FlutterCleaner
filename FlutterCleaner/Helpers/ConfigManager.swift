//
//  ConfigManager.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation

struct ConfigManager {
    private static var configURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/FlutterCleaner/config.json")
    }

    static func saveFlutterPath(_ path: String) {
        let dir = configURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dict = ["flutterPath": path]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            try? data.write(to: configURL)
        }
        AppLogger.log("💾 Saved Flutter path to config: \(path)")
    }

    static func loadFlutterPath() -> String? {
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let path = json["flutterPath"] else {
            AppLogger.log("⚠️ Config missing or unreadable at \(configURL.path)")
            return nil
        }

        guard FileManager.default.isExecutableFile(atPath: path) else {
            AppLogger.log("⚠️ Flutter path found in config but not executable: \(path)")
            return nil
        }

        return path
    }
}
