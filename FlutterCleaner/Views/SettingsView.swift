//
//  SettingsView.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var flutterPath: String? = ConfigManager.loadFlutterPath()
    @State private var showToast = false
    @AppStorage("deepClean") private var deepClean = false
    @AppStorage("autoCleanEnabled") private var autoCleanEnabled = false
    @AppStorage("customIntervalDays") private var customIntervalDays = 7

    var body: some View {
        ZStack(alignment: .bottom) {
            if Bundle.main.isQuarantined {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("App Quarantined — run the setup command to fix")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }
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

                // MARK: Advanced Tab
                advancedTab
                    .tabItem {
                        Label("Advanced", systemImage: "hammer")
                    }
            }
            .frame(width: 480, height: 320)
            .padding()

            if showToast {
                ToastView(message: "✅ Flutter SDK configured successfully!")
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            flutterPath = ConfigManager.loadFlutterPath()
        }
        .onReceive(NotificationCenter.default.publisher(for: .flutterSDKConfigured)) { _ in
            showToastAnimated()
        }
    }

    // MARK: - Toast Animation Helper
    private func showToastAnimated() {
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
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

            HStack {
                Text("Run every")
                TextField("Days", value: $customIntervalDays, formatter: NumberFormatter())
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: customIntervalDays) { _, _ in
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

            HStack(spacing: 8) {
                // Editable text field for SDK path
                TextField("No SDK path set", text: Binding(
                    get: { flutterPath ?? "" },
                    set: { newValue in
                        flutterPath = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if FileManager.default.isExecutableFile(atPath: newValue) {
                            ConfigManager.saveFlutterPath(newValue)
                            AppLogger.log("✅ Flutter path updated manually: \(newValue)")
                        }
                    })
                )
                .textFieldStyle(.plain)
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                .font(.caption)
                .textSelection(.enabled)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)

                // Change (folder) icon
                Button {
                    if let path = FlutterPathPicker.pickFlutterBinary() {
                        flutterPath = path.path
                        ConfigManager.saveFlutterPath(path.path)
                        AppLogger.log("✅ Flutter path changed via picker: \(path.path)")
                        showToastAnimated()
                    }
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                        .help("Change Flutter SDK Location")
                }
                .buttonStyle(.borderless)

                // Reveal in Finder
                if let path = flutterPath {
                    Button {
                        let folder = URL(fileURLWithPath: path).deletingLastPathComponent()
                        NSWorkspace.shared.open(folder)
                    } label: {
                        Image(systemName: "magnifyingglass.circle")
                            .help("Reveal SDK in Finder")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.top, 4)

            // Inline recent log preview
            let logURL = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/FlutterCleaner.log")

            if let logText = try? String(contentsOf: logURL, encoding: .utf8),
               !logText.isEmpty {
                let lastLines = logText.split(separator: "\n").suffix(20).joined(separator: "\n")

                ScrollView {
                    Text(lastLines)
                        .font(.system(.caption2, design: .monospaced))
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

#Preview("Settings") {
    SettingsView()
        .frame(width: 600, height: 400)
        .preferredColorScheme(.light)
}


#Preview("Settings Dark") {
    SettingsView()
        .frame(width: 600, height: 400)
        .preferredColorScheme(.dark)
}
