//
//  FlutterCleanerApp.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import SwiftUI

@main
struct FlutterCleanerApp: App {
init() {
    // Ensure disk access
    PermissionManager.promptForFullDiskAccessIfNeeded()

    // Try loading saved config first
    if let saved = ConfigManager.loadFlutterPath(),
       FileManager.default.isExecutableFile(atPath: saved) {
        AppLogger.log("✅ Using saved Flutter SDK path: \(saved)")
    } else if let detected = Cleaner.detectFlutterPath() {
        AppLogger.log("✅ Auto-detected Flutter SDK at: \(detected)")
        ConfigManager.saveFlutterPath(detected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(name: .flutterSDKConfigured, object: nil)
        }
    } else {
        // Couldn’t detect -> prompt user
        let alert = NSAlert()
        alert.messageText = "Flutter SDK Not Found"
        alert.informativeText = """
        Flutter Cleaner couldn’t find your Flutter SDK automatically.
        Please select your Flutter SDK folder (e.g. ~/flutter)
        or binary (e.g. ~/flutter/bin/flutter).
        """
        alert.addButton(withTitle: "Select SDK")
        alert.runModal()
        _ = FlutterPathPicker.pickFlutterBinary()
    }

    // Handle launchd auto-clean mode
    if CommandLine.arguments.contains("--auto") {
        AutoCleaner.run()
        exit(0)
    }
}

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 500)
        }

        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let flutterSDKConfigured = Notification.Name("flutterSDKConfigured")
}
