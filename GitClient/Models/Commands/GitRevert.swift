//
//  GitRevert.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import Foundation

struct GitRevert: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "revert",
        ]
        if let parentNumber {
            args.append("-m")
            args.append(String(parentNumber))
        }
        args.append(commitHash)
        return args
    }
    var directory: URL
    var commitHash: String
    var parentNumber: Int?

    func parse(for stdOut: String) -> Void {}
}
