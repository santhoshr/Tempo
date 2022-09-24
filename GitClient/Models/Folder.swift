//
//  Folders.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Folder: Hashable, Codable {
    var url: URL
    var displayName: String {
        url.path.components(separatedBy: "/").filter{ !$0.isEmpty }.last ?? ""
    }
}
