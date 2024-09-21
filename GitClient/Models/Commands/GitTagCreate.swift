//
//  GitTagCraete.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import Foundation

struct GitTagCreate: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "tag",
            tagname,
            object,
        ]
    }
    var directory: URL
    var tagname: String
    var object: String

    func parse(for stdOut: String) throws -> OutputModel {}
}
