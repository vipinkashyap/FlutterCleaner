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

    DispatchQueue.global(qos: .userInitiated).async {
        if let saved = ConfigManager.loadFlutterPath(),
           FileManager.default.isExecutableFile(atPath: saved) {
            AppLogger.log("✅ Using saved Flutter SDK path: \(saved)")
        } else if let detected = Cleaner.detectFlutterPath() {
            AppLogger.log("✅ Auto-detected Flutter SDK: \(detected)")
            ConfigManager.saveFlutterPath(detected)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: .flutterSDKConfigured, object: detected)
            }
        } else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Flutter SDK Not Found"
                alert.informativeText = "Please select your Flutter SDK folder or binary."
                alert.addButton(withTitle: "Select SDK")
                alert.runModal()
                _ = FlutterPathPicker.pickFlutterBinary()
            }
        }
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
