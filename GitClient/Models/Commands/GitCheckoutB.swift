//
//  GitCheckoutB.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/06.
//

import Foundation

struct GitCheckoutB: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "checkout",
            "-b",
            newBranchName,
            startPoint,
        ]
    }
    var directory: URL
    var newBranchName: String
    var startPoint: String

    func parse(for stdOut: String) -> Void {}
}
