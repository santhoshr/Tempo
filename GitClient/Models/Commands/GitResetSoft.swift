//
//  GitResetSoft.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitResetSoft: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        return [
            "git",
            "reset",
            "--soft",
            commitHash
        ]
    }
    var directory: URL
    /// The commit hash to reset to
    var commitHash: String

    func parse(for stdOut: String) -> Void {}
}