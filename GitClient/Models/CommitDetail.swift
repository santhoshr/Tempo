//
//  CommitDetail.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/08.
//

import Foundation

struct CommitDetail {
    var hash: String
    var abbreviatedParentHashes: [String]
    var author: String
    var authorEmail: String
    var authorDate: String
    var title: String
    var body: String
    var branches: [String]
    var tags: [String]
    var diff: Diff
}
