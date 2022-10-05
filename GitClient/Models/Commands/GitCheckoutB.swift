//
//  GitCheckoutB.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/06.
//

import Foundation

struct GitCheckoutB: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "checkout",
            "-b",
            newBranchName,
        ]
    }
    var directory: URL
    var newBranchName: String

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
