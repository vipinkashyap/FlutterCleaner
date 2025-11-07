//
//  Cleaner.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation

class Cleaner {
    static let shared = Cleaner()
    private init() {}

    func clean(project: FlutterProject, includePods: Bool = false, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var command = "cd \"\(project.path)\" && flutter clean"
            if includePods {
                command += " && rm -rf ios/Pods"
            }

            let process = Process()
            process.launchPath = "/bin/zsh"
            process.arguments = ["-c", command]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.launch()
            process.waitUntilExit()
            AppLogger.log("Cleaned project \(project.name) – status: \(process.terminationStatus)")

            DispatchQueue.main.async {
                completion(process.terminationStatus == 0)
            }
        }
    }

    func manualDelete(project: FlutterProject, includePods: Bool = false) {
        let fm = FileManager.default
        var dirs = ["build", ".dart_tool"]
        if includePods {
            dirs.append("ios/Pods")
        }
        for dir in dirs {
            let path = URL(fileURLWithPath: project.path).appendingPathComponent(dir)
            try? fm.removeItem(at: path)
        }
    }
}
