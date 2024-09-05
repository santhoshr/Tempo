//
//  GitStatus.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/06.
//

import Foundation

struct GitStatus: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "status",
            "--short",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
