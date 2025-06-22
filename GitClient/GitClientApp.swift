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
    @State var expandAllFiles: UUID?
    @State var collapseAllFiles: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.openAIAPISecretKey, keychainStorage.openAIAPISecretKey)
                .environment(\.expandAllFiles, expandAllFiles)
                .environment(\.collapseAllFiles, collapseAllFiles)
                .errorSheet($keychainStorage.error)
        }
        .commands {
            CommandGroup(before: .toolbar) {
                Button("Expand All Files") {
                    expandAllFiles = UUID()
                }
                .keyboardShortcut(.rightArrow, modifiers: .option)
                Button("Collapse All Files") {
                    collapseAllFiles = UUID()
                }
                .keyboardShortcut(.leftArrow, modifiers: .option)
            }
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
