//
//  AppLogger.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation
import os

struct AppLogger {
    private static let logURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/FlutterCleaner.log")

    static func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: .now)
        let line = "[\(timestamp)] \(message)\n"

        // Write to file
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }

        // Mirror to unified system log
        os_log("%{public}@", log: .default, type: .info, message)
    }
}