//
//  AppStorage+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/24.
//

import Foundation

enum AppStorageKey: String {
    case folder
    case commitMessageTemplate
}

struct AppStorageDefaults {
    static let commitMessageTemplate = try! JSONEncoder().encode(["Tweaks", "Fix lint warnings"])
}
