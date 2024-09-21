//
//  GitRevert.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import Foundation

struct GitRevert: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "revert",
            commitHash,
        ]
    }
    var directory: URL
    var commitHash: String

    func parse(for stdOut: String) -> Void {}
}
