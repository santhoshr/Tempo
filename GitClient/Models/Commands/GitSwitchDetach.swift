//
//  GitSwitchDetach.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/18.
//
import Foundation

struct GitSwitchDetach: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "switch",
            "–detach",
            branchName,
        ]
    }
    var directory: URL
    var branchName: String

    func parse(for stdOut: String) -> Void {}
}
