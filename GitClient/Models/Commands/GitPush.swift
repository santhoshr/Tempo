//
//  GitPush.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/29.
//

import Foundation

struct GitPush: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "push",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec = "HEAD"

    func parse(for stdOut: String) -> Void {}
}
