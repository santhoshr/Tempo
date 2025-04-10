//
//  GitShowref.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Foundation

struct GitShowref: Git {
    var arguments: [String] {
        [
            "git",
            "show-ref",
            pattern
        ]
    }
    var directory: URL
    /// Show references matching one or more patterns. Patterns are matched from the end of the full name, and only complete parts are matched, e.g. master matches refs/heads/master, refs/remotes/origin/master, refs/tags/jedi/master but not refs/heads/mymaster or refs/remotes/master/jedi.
    var pattern: String

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
