//
//  EnvironmentLoader.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation

enum EnvironmentLoader {
    /// Loads the user's login shell environment variables.
    /// This ensures PATH, HOME, and other vars are the same as in Terminal.
    static func loginShellEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/usr/bin/env"
        process.arguments = ["bash", "-l", "-c", "env"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            print("⚠️ Failed to run login shell for env: \(error)")
            return env
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return env
        }

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                env[parts[0]] = parts[1]
            }
        }

        return env
    }
}