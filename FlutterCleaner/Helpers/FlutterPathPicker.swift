import Foundation
import AppKit
import UniformTypeIdentifiers

final class FlutterPathPicker {
    private static let bookmarkKey = "flutterBinaryBookmark"

    /// Prompts user to select flutter binary.
    static func pickFlutterBinary() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Flutter Binary"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.init(filenameExtension: "flutter")!]
        panel.message = "Locate your Flutter executable (e.g. ~/flutter/bin/flutter)"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            AppLogger.log("✅ Saved Flutter binary bookmark: \(url.path)")
            return url
        } catch {
            AppLogger.log("⚠️ Failed to save security bookmark: \(error)")
            return nil
        }
    }

    /// Restores previously saved flutter binary with security scope.
    static func restoreFlutterBinary() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            AppLogger.log("⚠️ No saved Flutter bookmark found.")
            return nil
        }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale { AppLogger.log("⚠️ Bookmark is stale.") }
            guard url.startAccessingSecurityScopedResource() else {
                AppLogger.log("⚠️ Failed to start security scope.")
                return nil
            }
            return url
        } catch {
            AppLogger.log("⚠️ Failed to restore bookmark: \(error)")
            return nil
        }
    }
}
