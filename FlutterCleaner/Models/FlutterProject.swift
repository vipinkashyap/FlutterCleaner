//
//  FlutterProject.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation

struct FlutterProject: Identifiable, Hashable {
    let id = UUID()
    let path: String
    var size: UInt64 = 0
    var isCleaning: Bool = false
    var lastModified: Date = .distantPast   // 👈 new
    var isStale: Bool {                     // 👈 new
        lastModified < Date().addingTimeInterval(-60 * 60 * 24 * 90) // 90 days old
    }

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
