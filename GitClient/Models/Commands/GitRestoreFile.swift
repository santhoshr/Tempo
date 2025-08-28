//
//  GitRestoreFile.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitRestoreFile: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "restore",
            filePath,
        ]
    }
    var directory: URL
    var filePath: String

    func parse(for stdOut: String) -> Void {}
}