//
//  GitAddPathspec.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import Foundation

struct GitAddPathspec: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "add",
            pathspec,
        ]
    }
    var directory: URL
    var pathspec: String

    func parse(for stdOut: String) -> Void {}
}
