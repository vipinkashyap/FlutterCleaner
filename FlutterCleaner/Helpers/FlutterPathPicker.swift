import Foundation
import AppKit

final class FlutterPathPicker {
    static func pickFlutterBinary() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Flutter SDK Folder or Binary"
        panel.message = """
        Select your Flutter SDK folder (e.g. ~/flutter)
        or binary (e.g. ~/flutter/bin/flutter).
        """
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        // Auto-detect existing flutter
        if let detected = Cleaner.detectFlutterPath() {
            panel.directoryURL = URL(fileURLWithPath: detected).deletingLastPathComponent()
        } else {
            panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("flutter")
        }

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        var finalPath = url.path
        let candidate = url.appendingPathComponent("bin/flutter")
        if FileManager.default.isExecutableFile(atPath: candidate.path) {
            finalPath = candidate.path
        }

        guard FileManager.default.isExecutableFile(atPath: finalPath) else {
            let alert = NSAlert()
            alert.messageText = "Invalid Flutter SDK Path"
            alert.informativeText = "Please select a valid Flutter SDK or binary."
            alert.runModal()
            return nil
        }

        ConfigManager.saveFlutterPath(finalPath)
        AppLogger.log("✅ Saved Flutter binary path: \(finalPath)")
        return URL(fileURLWithPath: finalPath)
    }
    
    
    /// Restores the saved Flutter binary path from config, if it exists and is executable.
    static func restoreFlutterBinary() -> URL? {
        if let savedPath = ConfigManager.loadFlutterPath(),
           FileManager.default.isExecutableFile(atPath: savedPath) {
            return URL(fileURLWithPath: savedPath)
        } else {
            AppLogger.log("⚠️ No valid saved Flutter binary found.")
            return nil
        }
    }
}
