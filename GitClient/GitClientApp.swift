//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

@main
struct GitClientApp: App {
    @StateObject var keychainStorage = KeychainStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.openAIAPISecretKey, keychainStorage.openAIAPISecretKey)
                .errorSheet($keychainStorage.error)
        }
        Settings {
            SettingsView(openAIAPISecretKey: $keychainStorage.openAIAPISecretKey)
                .environment(\.openAIAPISecretKey, keychainStorage.openAIAPISecretKey)
        }
        Window("Commit Message Snippets", id: WindowID.commitMessageSnippets.rawValue) {
            CommitMessageSnippetView()
        }
    }
}
