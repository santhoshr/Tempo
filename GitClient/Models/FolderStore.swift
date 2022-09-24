//
//  FolderStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/21.
//

import Foundation

final class FolderStore: ObservableObject {
    @Published private(set) var folders: [Folder] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults.standard) throws {
        self.defaults = defaults
        guard let data = defaults.data(forKey: .folder) else
             {
            return
        }
        let decoder = JSONDecoder()
        folders = try decoder.decode([Folder].self, from: data)
    }

    func add(_ folder: Folder) throws {
        folders.insert(folder, at: 0)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(folders)
        defaults.set(encoded, forKey: .folder)
    }
}

extension UserDefaults {
    enum Key: String {
        case folder
    }

    func data(forKey key: UserDefaults.Key) -> Data? {
        data(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: UserDefaults.Key) {
        set(value, forKey: key.rawValue)
    }
}
