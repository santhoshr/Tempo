//
//  GitSwitch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct GitSwitch: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "switch",
            branchName,
        ]
    }
    var directory: URL
    var branchName: String

    func parse(for stdOut: String) -> Void {}
}
