//
//  AppLogger.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation
import OSLog

struct AppLogger {
    private static let logURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/FlutterCleaner.log")

    private static let logger = Logger(subsystem: "com.example.FlutterCleaner", category: "App")

    private static let queue = DispatchQueue(label: "AppLoggerQueue", qos: .utility)

    static func log(_ message: String) {
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: .now)
            let line = "[\(timestamp)] \(message)\n"
            guard let data = line.data(using: .utf8) else { return }

            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: logURL)
            }

            logger.info("\(message, privacy: .public)")
        }
    }
}
