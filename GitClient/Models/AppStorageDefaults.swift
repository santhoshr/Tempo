//
//  AppStorageDefaults.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import Foundation

struct AppStorageDefaults {
    static let commitMessageTemplate = try! JSONEncoder().encode(["Tweaks", "Fix lint warnings"])
}
