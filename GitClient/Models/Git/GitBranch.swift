//
//  GitBranch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct GitBranch: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "branch",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
