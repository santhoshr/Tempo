//
//  Commit.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Commit: Hashable {
    var hash: String
    var author: String
    var authorDateRelative: String
    var title: String
}
