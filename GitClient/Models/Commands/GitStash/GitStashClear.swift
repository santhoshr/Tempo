//
//  GitStashClear.swift
//  GitClient
//
//  Created by Rovo Dev on 2025/08/28.
//

import Foundation

struct GitStashClear: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "stash",
            "clear"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
