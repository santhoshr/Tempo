//
//  GitCheckout.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/12.
//

import Foundation

struct GitCheckout: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "checkout",
            commitHash,
        ]
    }
    var directory: URL
    var commitHash: String

    func parse(for stdOut: String) -> Void {}
}
