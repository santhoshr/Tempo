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
                try db.label("OpenAI API Secret Key for Tempo.app").comment("The secret key used for AI-powered staging and commit message generation.").set(openAIAPISecretKey, key: key)
            } catch {
                self.error = error
            }
        }
    }
    @Published var error: Error?
    private let db = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-secret-key")
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
