//
//  GitRestorePatch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/05.
//

import Foundation

struct GitRestorePatch: InteractiveGit {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "restore",
            "--staged",
            "--patch",
        ]
    }
    var directory: URL
    var inputs: [String]

    func parse(for stdOut: String) -> Void {}
}
