//
//  FlutterCleanerApp.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import SwiftUI
import Foundation

extension Bundle {
    var isQuarantined: Bool {
        let attr = "com.apple.quarantine"
        return getxattr(bundlePath, attr, nil, 0, 0, 0) >= 0
    }
}

@main
struct FlutterCleanerApp: App {

    @State private var showQuarantineAlert = false

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
                .sheet(isPresented: $showQuarantineAlert, content: {
                    VStack(spacing: 16) {
                        Text("FlutterCleaner Requires One-Time Setup")
                            .font(.headline)
                            .padding(.top)

                        Text("""
                        macOS has quarantined this app since it's not notarized.

                        Run this command in Terminal:
                        """)
                        .multilineTextAlignment(.center)

                        Text("sudo xattr -rd com.apple.quarantine /Applications/FlutterCleaner.app")
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(8)
                            .onTapGesture {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(
                                    "sudo xattr -rd com.apple.quarantine /Applications/FlutterCleaner.app",
                                    forType: .string
                                )
                            }

                        Button("Copy Command") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(
                                "sudo xattr -rd com.apple.quarantine /Applications/FlutterCleaner.app",
                                forType: .string
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Run in Terminal…") {
                            let command = "sudo xattr -rd com.apple.quarantine /Applications/FlutterCleaner.app"
                            let appleScript = "tell application \\\"Terminal\\\" to do script \\\"\(command)\\\""
                            let task = Process()
                            task.launchPath = "/usr/bin/osascript"
                            task.arguments = ["-e", appleScript]
                            task.launch()
                        }
                        .buttonStyle(.bordered)

                        Button("Close") {
                            showQuarantineAlert = false
                        }
                        .padding(.bottom)
                    }
                    .frame(width: 420)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .transition(.move(edge: .bottom))
                }).onAppear {
                    if Bundle.main.isQuarantined {
                        DispatchQueue.main.async {
                           showQuarantineAlert = true
                           }
                    }
                }
        }

        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let flutterSDKConfigured = Notification.Name("flutterSDKConfigured")
}
