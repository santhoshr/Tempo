//
//  GitRevParse.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/12.
//

import Foundation

struct GitRevParse: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
            "git",
            "rev-parse",
        ]
        if !gitPath.isEmpty {
            args.append("--git-path")
            args.append(gitPath)
        }
        return args
    }
    var directory: URL
    var gitPath: String

    func parse(for stdOut: String) -> String {
        stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
