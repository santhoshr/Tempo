//
//  GitCommit.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import Foundation

struct GitCommit: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "commit",
            "-m",
            message,
        ]
    }
    var directory: URL
    var message: String

    func parse(for stdOut: String) -> Void {}
}
