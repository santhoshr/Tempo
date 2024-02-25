//
//  GitAdd.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import Foundation

struct GitAdd: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "add",
            ".",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
