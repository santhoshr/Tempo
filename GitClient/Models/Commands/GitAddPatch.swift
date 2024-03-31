//
//  GitAddPatch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/02.
//

import Foundation

struct GitAddPatch: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "add",
            "--patch",
        ]
    }
    var directory: URL
    var inputs: [String]

    func parse(for stdOut: String) -> Void {}
}
