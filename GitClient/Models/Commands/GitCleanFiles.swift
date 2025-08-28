//
//  GitCleanFiles.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitCleanFiles: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        return [
            "git",
            "clean",
            "-f"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}