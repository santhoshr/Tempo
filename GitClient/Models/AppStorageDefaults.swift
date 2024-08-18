//
//  AppStorageDefaults.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import Foundation

struct AppStorageDefaults {
    static let commitMessageSnippets = try! JSONEncoder().encode(["Tweaks", "Remove unused code", "Fix lint warnings"])
}
