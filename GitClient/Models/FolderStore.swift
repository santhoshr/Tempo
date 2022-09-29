//
//  FolderStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/21.
//

import Foundation

struct FolderStore {
    static let defaults = UserDefaults.standard

    static func folders() throws -> [Folder] {
        guard let data = defaults.data(forKey: .folder) else
             {
            throw GenericError(errorDescription: "The data object associated with the specified key, or nil if the key does not exist or its value is not a data object.")
        }
        let decoder = JSONDecoder()
        return try decoder.decode([Folder].self, from: data)
    }

    static func save(_ folders: [Folder]) throws {
        let prefix = Array(folders.prefix(100))
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(prefix)
        defaults.set(encoded, forKey: .folder)
    }
}
