//
//  ContentView.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//

import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    @StateObject private var scanner = ProjectScanner()
    @State private var selectedFolder: URL?
    @State private var isScanning = false
    @State private var cleaningIDs = Set<UUID>()
    @AppStorage("deepClean") private var deepClean = false   // 👈 now auto-saved
    @AppStorage("autoCleanEnabled") private var autoCleanEnabled = false
    @State private var isCleaningAll = false
    @State private var cleanSummary: (count: Int, bytes: UInt64)? = nil
    @State private var completedCount = 0
    @State private var showConfirm = false
    @State private var searchText = ""

    /// Computed property for total size
    private var totalSize: UInt64 {
        scanner.projects.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack {

            if let folder = selectedFolder {
                Text("Last scanned folder: \(folder.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
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
                    if deepClean {
                        showConfirm = true
                    } else {
                        cleanAllProjects()
                    }
                }
                .alert("Confirm Deep Clean?", isPresented: $showConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Proceed") { cleanAllProjects() }
                } message: {
                    Text("This will also delete iOS/Pods folders. You’ll need to run `pod install` again later.")
                }
                .disabled(isCleaningAll || scanner.projects.isEmpty)
                .padding(.leading, 4)

                Toggle("Deep Clean (include iOS Pods)", isOn: $deepClean)
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.leading, 20)
                Toggle("Auto Clean weekly", isOn: $autoCleanEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: autoCleanEnabled) {
                        if autoCleanEnabled {
                            LaunchdScheduler.enableAutoClean()
                        } else {
                            LaunchdScheduler.disableAutoClean()
                        }
                    }
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
                TextField("Search by name or path", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom])
 
                let filteredProjects = scanner.projects.filter {
                    searchText.isEmpty ||
                    $0.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.path.localizedCaseInsensitiveContains(searchText)
                }

                List(filteredProjects) { project in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(project.name)
                                    .bold()
                                    .foregroundColor(project.isStale ? .gray : .primary)
                                if project.isStale {
                                    Text("🕒")
                                }
                            }
                            Text(project.path)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(formatBytes(project.size))
                            .foregroundColor(project.isStale ? .gray : .primary)
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
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: project.path)])
                        } label: {
                            Label("Reveal", systemImage: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Divider()
                HStack {
                    Text("Total \(scanner.projects.count) projects")
                    Spacer()
                    Text("Total size: \(formatBytes(totalSize))")
                    if let summary = cleanSummary {
                        Spacer()
                        Text("Freed this session: \(formatBytes(summary.bytes))")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding([.horizontal, .bottom])
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .onAppear {
            if let lastPath = UserDefaults.standard.string(forKey: "lastFolder") {
                let url = URL(fileURLWithPath: lastPath)
                selectedFolder = url
                scanner.scan(in: url)
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
            UserDefaults.standard.set(url.path, forKey: "lastFolder")
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
    
    // MARK: - Helpers

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview("Main Screen - Sample Projects") {
    let scanner = ProjectScanner()
    scanner.projects = [
        FlutterProject(path: "/Users/vkk/Play/MyApp", size: 125_000_000, lastModified: Date()),
        FlutterProject(path: "/Users/vkk/Play/OldProject", size: 512_000_000, lastModified: Date().addingTimeInterval(-60*60*24*120))
    ]
    return ContentView()
        .environmentObject(scanner)
        .frame(width: 700, height: 500)
        .preferredColorScheme(.light)
}
