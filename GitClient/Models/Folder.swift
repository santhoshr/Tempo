//
//  Folders.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Folder: Hashable, Codable {
    var path: String
    var displayName: String {
        path.components(separatedBy: "/").filter{ !$0.isEmpty }.last ?? ""
    }
}
