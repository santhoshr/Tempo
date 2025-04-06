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
        arg.append(branchName)
        return arg
    }
    var directory: URL
    var isRemote = false
    var branchName: String

    func parse(for stdOut: String) throws -> Void {}
}
