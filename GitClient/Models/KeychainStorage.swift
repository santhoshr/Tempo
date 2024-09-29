//
//  KeychainStorage.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/28.
//

import Foundation
import KeychainAccess

final class KeychainStorage: ObservableObject {
    @Published var openAIAPISecretKey: String {
        didSet {
            do {
                try db.set(openAIAPISecretKey, key: key)
            } catch {
                self.error = error
            }
        }
    }
    @Published var error: Error?
    private let db = Keychain()
    private let key = "OpenAIAPISecretKey"

    init() {
        do {
            let secretKey = try db.get(key)
            self.openAIAPISecretKey = secretKey ?? ""
        } catch {
            self.openAIAPISecretKey = ""
            self.error = error
        }
    }
}
