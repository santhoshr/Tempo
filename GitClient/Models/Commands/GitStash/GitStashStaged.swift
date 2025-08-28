//
//  GitStashStaged.swift
//  GitClient
//
//  Created by Santhosh R on 2025/08/27.
//

import Foundation

struct GitStashStaged: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "stash",
            "push",
            "--staged",
        ]
        if keepIndex {
            args.append("--keep-index")
        }
        if !message.isEmpty {
            args.append("-m")
            args.append(message)
        }
        return args
    }
    var directory: URL
    var message = ""
    var keepIndex: Bool = false

    func parse(for stdOut: String) -> Void {}
}
