//
//  FileSizeFormatter.swift
//  FlutterCleaner
//
//  Created by Vipin Kumar Kashyap on 11/7/25.
//


import Foundation

func formatBytes(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}