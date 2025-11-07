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

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}