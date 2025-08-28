//
//  GitResetToHead.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitResetToHead: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        return [
            "git",
            "reset",
            "--hard",
            "HEAD"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}