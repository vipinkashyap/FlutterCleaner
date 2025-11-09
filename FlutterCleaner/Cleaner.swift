//
//  Cleaner.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import Foundation
import AppKit

final class Cleaner {
    static let shared = Cleaner()
    private init() {}

    func clean(project: FlutterProject, includePods: Bool = false, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let flutterURL = FlutterPathPicker.restoreFlutterBinary() else {
                AppLogger.log("⚠️ No Flutter binary selected or accessible.")
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Start security scope
            guard flutterURL.startAccessingSecurityScopedResource() else {
                AppLogger.log("⚠️ Failed to start security scope for Flutter binary.")
                DispatchQueue.main.async { completion(false) }
                return
            }

            defer {
                flutterURL.stopAccessingSecurityScopedResource()
            }

            let flutterPath = flutterURL.path
            AppLogger.log("Using Flutter path: \(flutterPath)")

            // Build the clean command
            let command = "cd '\(project.path)' && '\(flutterPath)' clean"
            AppLogger.log("🧹 Running clean for \(project.name)")
            AppLogger.log("Command: \(command)")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                AppLogger.log("❌ Failed to run clean: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }

            process.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if !output.isEmpty { AppLogger.log(output) }

            let success = process.terminationStatus == 0
            AppLogger.log(success ? "✅ Clean succeeded" : "❌ Clean failed (exit \(process.terminationStatus))")

            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    /// Detect flutter path via shell
    static func detectFlutterPath() -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "which flutter"]
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return path?.isEmpty == true ? nil : path
    }
}
