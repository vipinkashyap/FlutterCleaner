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
