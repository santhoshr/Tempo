//
//  GitShow.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/02.
//

import Foundation

struct GitShow: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "show",
            object,
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
