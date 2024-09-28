//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

@main
struct GitClientApp: App {
    @StateObject var keychainStorage = KeyChainStorage(openAIAPISecretKey: "")

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
        Window("Commit Message Snippets", id: WindowID.commitMessageSnippets.rawValue) {
            CommitMessageSnippetView()
        }
    }
}
