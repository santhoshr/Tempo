//
//  GitDiffNumStat.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import Foundation

struct GitDiffNumStat: Git {
    typealias OutputModel = DiffStat
    var arguments: [String] {
        var args = [
           "git",
           "diff",
           "--no-renames",
           "--numstat",
        ]
        if cached {
            args.append("--cached")
        }
        return args
    }
    var directory: URL
    var cached = false

    func parse(for stdOut: String) -> DiffStat {
        let lines = stdOut.components(separatedBy: .newlines)
        let splitted = lines.map { line in
            line.split(separator: " ")
        }
        return .init(
            files: splitted.map {String($0[2])},
            insertions: splitted.map { Int($0[0]) ?? 0 },
            deletions: splitted.map { Int($0[1]) ?? 0 }
        )
    }
}
