//
//  GitDiff.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/26.
//

import Foundation

struct GitDiff: Git {
    typealias OutputModel = String
    var arguments = [
        "diff",
    ]
    var directory: URL

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
