//
//  GitBranchDelete.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/07.
//

import Foundation

struct GitBranchDelete: Git {
    var arguments: [String] {
        var arg = [
            "git",
            "branch",
            "--delete",
        ]
        if isRemote {
            arg.append("-r")
        }
        return arg
    }
    var directory: URL
    var isRemote = false

    func parse(for stdOut: String) throws -> Void {}
}
