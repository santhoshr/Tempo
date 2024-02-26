//
//  GitPush.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/29.
//

import Foundation

struct GitPush: Git {
    typealias OutputModel = Void
    var arguments = [
        "git",
        "push",
        "origin",
        "HEAD",
    ]
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
