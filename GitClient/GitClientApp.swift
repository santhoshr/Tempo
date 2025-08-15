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
                .environment(\.openAIAPIURL, keychainStorage.openAIAPIURL)
                .environment(\.openAIAPIPrompt, keychainStorage.openAIAPIPrompt)
                .environment(\.openAIAPIModel, keychainStorage.openAIAPIModel)
                .environment(\.openAIAPIStagingPrompt, keychainStorage.openAIAPIStagingPrompt)
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
                Divider()
            }
        }
        Settings {
            SettingsView(
                openAIAPISecretKey: $keychainStorage.openAIAPISecretKey,
                openAIAPIURL: $keychainStorage.openAIAPIURL,
                openAIAPIPrompt: $keychainStorage.openAIAPIPrompt,
                openAIAPIModel: $keychainStorage.openAIAPIModel,
                openAIAPIStagingPrompt: $keychainStorage.openAIAPIStagingPrompt
            )
            .environment(\.openAIAPISecretKey, keychainStorage.openAIAPISecretKey)
            .environment(\.openAIAPIURL, keychainStorage.openAIAPIURL)
            .environment(\.openAIAPIPrompt, keychainStorage.openAIAPIPrompt)
            .environment(\.openAIAPIModel, keychainStorage.openAIAPIModel)
            .environment(\.openAIAPIStagingPrompt, keychainStorage.openAIAPIStagingPrompt)
        }
        Window("Commit Message Snippets", id: WindowID.commitMessageSnippets.rawValue) {
            CommitMessageSnippetView()
        }
    }
}
