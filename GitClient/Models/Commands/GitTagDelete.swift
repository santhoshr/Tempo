//
//  GitTagDelete.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import Foundation

struct GitTagDelete: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "tag",
            "-d",
            tagname,
        ]
    }
    var directory: URL
    var tagname: String

    func parse(for stdOut: String) throws -> OutputModel {}
}
