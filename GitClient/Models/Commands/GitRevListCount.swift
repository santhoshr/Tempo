//
//  GitRevListCount.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/24.
//

import Foundation

struct GitRevListCount: Git {
    typealias OutputModel = Int?
    var arguments: [String] {
        var args = [
            "git",
            "rev-list",
            "--count"
        ]
        args.append(commit)
        return args
    }
    var directory: URL
    var commit = "HEAD"

    func parse(for stdOut: String) -> Int? {
        Int(stdOut.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
