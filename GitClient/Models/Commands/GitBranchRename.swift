//
//  GitBranchRename.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/08.
//

import Foundation

struct GitBranchRename: Git {
    var arguments: [String] {
        var arg = [
            "git",
            "branch",
            "-m",
        ]
        arg.append(oldBranchName)
        arg.append(newBranchName)
        return arg
    }
    var directory: URL
    var oldBranchName: String
    var newBranchName: String

    func parse(for stdOut: String) throws -> Void {}
}
