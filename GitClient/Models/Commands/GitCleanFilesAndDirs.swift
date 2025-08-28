//
//  GitCleanFilesAndDirs.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitCleanFilesAndDirs: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        return [
            "git",
            "clean",
            "-fd"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}