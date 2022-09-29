//
//  GitPush.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/29.
//

import Foundation

struct GitPush: Git {
    typealias OutputModel = String
    var arguments = [
        "push",
        "origin",
        "HEAD",
    ]
    var directory: URL

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
