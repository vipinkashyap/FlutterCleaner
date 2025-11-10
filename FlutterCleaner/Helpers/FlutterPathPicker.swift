import Foundation
import AppKit

final class FlutterPathPicker {
    private static let flutterPathKey = "flutterBinaryPath"

    static func pickFlutterBinary() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Flutter Binary"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.message = "Locate your Flutter executable (e.g. ~/flutter/bin/flutter)"
        
        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: flutterPathKey)
            AppLogger.log("✅ Saved Flutter binary path: \(url.path)")
            return url
        }
        return nil
    }

    static func restoreFlutterBinary() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: flutterPathKey),
              FileManager.default.fileExists(atPath: path)
        else {
            AppLogger.log("⚠️ No saved Flutter path found.")
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}
