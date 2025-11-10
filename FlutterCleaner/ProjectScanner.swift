//
//  ProjectScanner.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation
import Combine

class ProjectScanner: ObservableObject {
    @Published var projects: [FlutterProject] = []
    private let fileManager = FileManager.default

    func scan(in root: URL) {
        guard PermissionManager.hasFullDiskAccess() else {
            AppLogger.log("⚠️ Missing Full Disk Access. Scan may be incomplete.")
            PermissionManager.promptForFullDiskAccessIfNeeded()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var found: [FlutterProject] = []
            let enumerator = self.fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            while let file = enumerator?.nextObject() as? URL {
                // Skip unnecessary folders to avoid deep recursion
                let path = file.path
                if path.contains("/.git/") || path.contains("/.gradle/") || path.contains("/node_modules/") {
                    continue
                }
                if file.lastPathComponent == "pubspec.yaml" {
                    let content = try? String(contentsOf: file,encoding: .utf8)
                    if content?.contains("flutter:") == true {
                        let dir = file.deletingLastPathComponent()
                        let size = self.directorySize(at: dir)
                        let attrs = try? self.fileManager.attributesOfItem(atPath: dir.path)
                        let lastModified = attrs?[.modificationDate] as? Date ?? .distantPast
                        found.append(FlutterProject(path: dir.path, size: size, lastModified: lastModified))
                    }
                }
            }

            DispatchQueue.main.async {
                self.projects = found
            }
        }
    }

    private func directorySize(at url: URL) -> UInt64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            total += UInt64(attrs?.fileSize ?? 0)
        }
        return total
    }
}
