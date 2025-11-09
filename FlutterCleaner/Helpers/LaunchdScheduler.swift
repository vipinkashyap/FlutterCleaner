import Foundation

struct LaunchdScheduler {
    static let agentPath = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.fluttercleaner.autoclean.plist")

    /// Create or update the LaunchAgent plist
    static func enableAutoClean() {
        let intervalDays = UserDefaults.standard.integer(forKey: "customIntervalDays")
        let interval = max(intervalDays, 1) * 60 * 60 * 24
        
     
        let plist: [String: Any] = [
            "Label": "com.fluttercleaner.autoclean",
            "ProgramArguments": [
                "/usr/bin/env",
                "open",
                "-a",
                "/Applications/FlutterCleaner.app",
                "--args",
                "--auto"
            ],            "StartInterval": interval,
            "RunAtLoad": true
        ]

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: agentPath)
            _ = shell("launchctl load \(agentPath.path)")
        } catch {
            print("Failed to create LaunchAgent: \(error)")
        }
    }

    /// Remove the LaunchAgent
    static func disableAutoClean() {
        _ = shell("launchctl unload \(agentPath.path)")
        try? FileManager.default.removeItem(at: agentPath)
    }

    /// Simple shell helper
    @discardableResult
    private static func shell(_ command: String) -> Int32 {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
