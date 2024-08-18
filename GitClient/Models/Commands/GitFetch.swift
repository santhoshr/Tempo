//
//  GitFetch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/18.
//

import Foundation

struct GitFetch: Git {
    typealias OutputModel = Void
    var arguments = [
        "git",
        "fetch",
    ]
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
