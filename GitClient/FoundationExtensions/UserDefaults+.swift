//
//  UserDefaults+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/24.
//

import Foundation

extension UserDefaults {
    enum Key: String {
        case folder
        case messageTemplate
        case initialConfigurationIsComplete
    }

    func data(forKey key: UserDefaults.Key) -> Data? {
        data(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: UserDefaults.Key) {
        set(value, forKey: key.rawValue)
    }
}

enum AppStorageKey: String {
    case folder
    case commitMessageTemplate
}

struct AppStorageDefaults {
    static let commitMessageTemplate = try! JSONEncoder().encode(["Tweaks", "Fix lint warnings"])
}
