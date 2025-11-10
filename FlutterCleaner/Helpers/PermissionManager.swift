//
//  PermissionManager.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/10/25.
//

import AppKit
import Foundation

enum PermissionManager {
    /// Check if we have read access to the user's home directory.
    static func hasFullDiskAccess() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let testFile = home.appendingPathComponent("Library/Preferences")
        return FileManager.default.isReadableFile(atPath: testFile.path)
    }

    /// Prompt the user to grant Full Disk Access via System Settings.
    static func promptForFullDiskAccessIfNeeded() {
        guard !hasFullDiskAccess() else { return }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Full Disk Access Required"
            alert.informativeText = """
            Flutter Cleaner needs Full Disk Access to scan and clean all your Flutter projects.
            Please open System Settings → Privacy & Security → Full Disk Access,
            then add Flutter Cleaner and enable the switch.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}