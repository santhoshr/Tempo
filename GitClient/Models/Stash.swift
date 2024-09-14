//
//  Stasg.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import Foundation

struct Stash: Identifiable {
    var id: Int { index }
    var index: Int
    var message: String
}
