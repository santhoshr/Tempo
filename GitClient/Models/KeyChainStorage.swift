//
//  KeyChainStorage.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/28.
//

import Foundation

final class KeyChainStorage: ObservableObject {
    @Published var openAIAPISecretKey: String

    init(openAIAPISecretKey: String) {
        self.openAIAPISecretKey = openAIAPISecretKey
    }
}
