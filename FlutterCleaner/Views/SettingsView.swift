//
//  SettingsView.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("deepClean") private var deepClean = false
    @AppStorage("autoCleanEnabled") private var autoCleanEnabled = false
    @AppStorage("customIntervalDays") private var customIntervalDays = 7

    var body: some View {
        TabView {
            // MARK: General Tab
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // MARK: Automation Tab
            automationTab
                .tabItem {
                    Label("Automation", systemImage: "clock.arrow.circlepath")
                }

            // MARK: Advanced Tab (placeholder)
            advancedTab
                .tabItem {
                    Label("Advanced", systemImage: "hammer")
                }
        }
        .frame(width: 480, height: 320)
        .padding()
    }

    // MARK: - Tabs

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Deep Clean (include iOS Pods)", isOn: $deepClean)
                .toggleStyle(SwitchToggleStyle())

            Text("When enabled, cleaning also removes iOS/Pods directories. This saves disk space but requires a fresh `pod install` next build.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    private var automationTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Auto Clean", isOn: $autoCleanEnabled)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: autoCleanEnabled) {
                    if autoCleanEnabled {
                        LaunchdScheduler.enableAutoClean()
                    } else {
                        LaunchdScheduler.disableAutoClean()
                    }
                }

            Text("Runs Flutter Cleaner automatically using macOS Launchd. The app doesn’t need to be open.")
                .font(.caption)
                .foregroundColor(.secondary)

            // 👇 New custom interval field
            HStack {
                Text("Run every")
                TextField("Days", value: $customIntervalDays, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: customIntervalDays) { _, newValue in
                        if autoCleanEnabled {
                            LaunchdScheduler.enableAutoClean()
                        }
                    }
                Text("days")
            }
            .font(.caption)
            .padding(.top, 4)
            

            Text("Customize how often the auto-clean runs. Minimum 1 day.")
                .font(.caption2)
                .foregroundColor(.secondary)

            Divider().padding(.vertical, 8)

            Button {
                AutoCleaner.run()
            } label: {
                Label("Clean Now", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)

            Text("Runs the cleaner immediately in the background using your saved settings.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    private var advancedTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced Options")
                .font(.headline)

            Text("Future features could include project exclusions, custom cleaning schedules, or integration with command-line tools.")
                .font(.caption)
                .foregroundColor(.secondary)

            // View Logs Button
            Button {
                let logURL = FileManager.default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Logs/FlutterCleaner.log")
                NSWorkspace.shared.open(logURL)
            } label: {
                Label("View Logs", systemImage: "doc.text.magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            
            // Inline recent log preview
            let logURL = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/FlutterCleaner.log")

            if let logText = try? String(contentsOf: logURL,encoding: .utf8),
               !logText.isEmpty {
                let lastLines = logText.split(separator: "\n").suffix(20).joined(separator: "\n")

                ScrollView {
                    Text(lastLines)
                        .font(.system(.caption2, design:.monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .padding(.top, 4)

                Text("Showing last 20 log entries.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("Opens the log file in TextEdit.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Spacer()
        }
        .padding()
    }
}

#Preview("Settings - Automation") {
    SettingsView()
        .frame(width: 600, height: 400)
        .preferredColorScheme(.light)
}

#Preview("Settings - Advanced (Logs)") {
    SettingsView()
        .frame(width: 600, height: 400)
        .preferredColorScheme(.light)
        // optionally, if your SettingsView uses @State tab selection:
        //.environment(\.selectedTab, "Advanced")
}
