//
//  ContentView.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = ProjectScanner()
    @State private var selectedFolder: URL?
    @State private var isScanning = false
    @State private var cleaningIDs = Set<UUID>()
    @State private var deepClean = false   // 👈 new state
    @State private var isCleaningAll = false
    @State private var cleanSummary: (count: Int, bytes: UInt64)? = nil

    /// Computed property for total size
    private var totalSize: UInt64 {
        scanner.projects.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack {
            HStack {
                Button("Select Folder") {
                    pickFolder()
                }
                .padding()
                .keyboardShortcut("o", modifiers: [.command])

                Button("Rescan") {
                    if let folder = selectedFolder { scanner.scan(in: folder) }
                }
                .disabled(selectedFolder == nil)
                .padding()

                Button("Clean All") {
                    cleanAllProjects()
                }
                .disabled(isCleaningAll || scanner.projects.isEmpty)
                .padding(.leading, 4)

                Toggle("Deep Clean (include iOS Pods)", isOn: $deepClean)
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.leading, 20)

                Spacer()
            }

            if let summary = cleanSummary {
                Text("Cleaned \(summary.count) project\(summary.count == 1 ? "" : "s") and freed \(formatBytes(summary.bytes))")
                    .font(.headline)
                    .padding(.bottom, 3)
            } else {
                Text("Total Space: \(formatBytes(totalSize))")
                    .font(.headline)
                    .padding(.bottom, 3)
            }

            if isScanning {
                ProgressView("Scanning...")
            } else if scanner.projects.isEmpty {
                Text("No Flutter projects found").foregroundColor(.secondary)
            } else {
                List(scanner.projects) { project in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(project.name).bold()
                            Text(project.path)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(formatBytes(project.size))
                        Button("Clean") {
                            cleaningIDs.insert(project.id)
                            Cleaner.shared.clean(project: project, includePods: deepClean) { success in
                                cleaningIDs.remove(project.id)
                                if success, let folder = selectedFolder {
                                    scanner.scan(in: folder)
                                }
                            }
                        }
                        .disabled(cleaningIDs.contains(project.id) || isCleaningAll)
                    }
                }
            }
        }
        .padding()
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            scanner.scan(in: url)
            cleanSummary = nil
        }
    }

    private func cleanAllProjects() {
        guard !scanner.projects.isEmpty else { return }
        isCleaningAll = true
        cleanSummary = nil
        let projectsToClean = scanner.projects
        let initialTotal = totalSize
        var cleanedCount = 0
        var cleanedBytes: UInt64 = 0
        var completed = 0
        let total = projectsToClean.count

        // Disable all Clean buttons by adding all IDs to cleaningIDs
        cleaningIDs.formUnion(projectsToClean.map { $0.id })

        func finishOne(project: FlutterProject, success: Bool) {
            completed += 1
            if success {
                cleanedCount += 1
            }
            if completed == total {
                // After all done, rescan to update sizes
                if let folder = selectedFolder {
                    scanner.scan(in: folder)
                }
                // Wait a bit for scan to complete, then update summary
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    let freed = initialTotal - totalSize
                    cleanSummary = (cleanedCount, freed)
                    isCleaningAll = false
                    cleaningIDs.subtract(projectsToClean.map { $0.id })
                }
            }
        }

        for project in projectsToClean {
            Cleaner.shared.clean(project: project, includePods: deepClean) { success in
                finishOne(project: project, success: success)
            }
        }
    }
}

#Preview {
    ContentView()
}
