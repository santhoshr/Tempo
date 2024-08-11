//
//  GitCommitAmend.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import Foundation

struct GitCommitAmend: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "commit",
            "--amend",
            "-m",
            message,
        ]
    }
    var directory: URL
    var message: String

    func parse(for stdOut: String) -> Void {}
}
