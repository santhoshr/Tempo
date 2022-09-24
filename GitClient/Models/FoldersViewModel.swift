//
//  FolderStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/21.
//

import Foundation

@MainActor
final class FoldersViewModel: ObservableObject {
    @Published private(set) var folders: [Folder] = []
    @Published private(set) var error: Error?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        guard let data = defaults.data(forKey: .folder) else
             {
            error = GenericError(errorDescription: "The data object associated with the specified key, or nil if the key does not exist or its value is not a data object.")
            return
        }
        let decoder = JSONDecoder()
        do {
            folders = try decoder.decode([Folder].self, from: data)
        } catch {
            self.error = error
        }
    }

    func newFolderDidChoose(url: URL) {
        do {
            try add(.init(path: url.absoluteString))
        } catch {
            self.error = error
        }
    }

    private func add(_ folder: Folder) throws {
        folders.insert(folder, at: 0)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(folders)
        defaults.set(encoded, forKey: .folder)
    }
}
