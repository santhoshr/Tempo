//
//  GitDiffShortStat.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import Foundation

struct GitDiffShortStat: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
           "git",
           "diff",
           "--no-renames",
           "--shortstat",
        ]
        if cached {
            args.append("--cached")
        }
        return args
    }
    var directory: URL
    var cached = false

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
