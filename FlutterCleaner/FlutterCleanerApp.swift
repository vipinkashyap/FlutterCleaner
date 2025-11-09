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
        // Attempt to detect flutter; if not found, prompt user for path
        if Cleaner.detectFlutterPath() == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = FlutterPathPicker.pickFlutterBinary()
            }
        }

        // Auto-clean support
        let args = CommandLine.arguments
        if args.contains("--auto") {
            AutoCleaner.run()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 500)
        }

        // 👇 Add this block:
        Settings {
            SettingsView()
        }
    }
}
