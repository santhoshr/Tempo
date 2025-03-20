//
//  Commit.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation
import CryptoKit

struct Commit: Hashable, Identifiable {
    var id: String { hash + branches.joined() + tags.joined() }
    var hash: String
    var abbreviatedParentHashes: [String]
    var author: String
    var authorEmail: String
    var authorDateRelative: String
    var title: String
    var rawBody: String
    var branches: [String]
    var tags: [String]
}
