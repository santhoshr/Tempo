//
//  GitRestore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/31.
//

import Foundation

struct GitRestore: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "restore",
            "--staged",
            ".",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
