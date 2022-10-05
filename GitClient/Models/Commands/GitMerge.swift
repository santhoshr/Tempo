//
//  GitMerge.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/06.
//

import Foundation

struct GitMerge: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "merge",
            branchName,
        ]
    }
    var directory: URL
    var branchName: String

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
