//
//  Commit.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Commit: Hashable, Identifiable {
    var id: String = UUID().uuidString
    var message: String
}
