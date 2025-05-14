//
//  GitDiff.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/26.
//

import Foundation

struct GitDiff: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
            "git",
            "diff",
        ]
        if noRenames {
            args.append("--no-renames")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        return args
    }
    var directory: URL
    var noRenames = true
    var revisionRange = ""

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
