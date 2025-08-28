//
//  GitStash.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
//

import Foundation

struct GitStash: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "stash",
            "push",
        ]
        if keepIndex {
            args.append("--keep-index")
        }
        if includeUntracked {
            args.append("--include-untracked")
        }
        if !message.isEmpty {
            args.append("-m")
            args.append(message)
        }
        return args
    }
    var directory: URL
    var message = ""
    var keepIndex: Bool = false
    var includeUntracked: Bool = false

    func parse(for stdOut: String) -> Void {}
}
