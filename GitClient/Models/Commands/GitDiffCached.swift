//
//  GitDiffCached.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/26.
//

import Foundation

struct GitDiffCached: Git {
    typealias OutputModel = String
    var arguments = [
        "git",
        "diff",
        "--cached",
    ]
    var directory: URL

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
