//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI
import Defaults

@main
struct GitClientApp: App {
    @State var expandAllFiles: UUID?
    @State var collapseAllFiles: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.openAIAPISecretKey, Defaults[.openAIAPIKey])
                .environment(\.openAIAPIURL, Defaults[.openAIAPIURL])
                .environment(\.openAIAPIPrompt, Defaults[.openAIAPIPrompt])
                .environment(\.openAIAPIModel, Defaults[.openAIAPIModel])
                .environment(\.openAIAPIStagingPrompt, Defaults[.openAIAPIStagingPrompt])
                .environment(\.expandAllFiles, expandAllFiles)
                .environment(\.collapseAllFiles, collapseAllFiles)
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
            SettingsView()
                .environment(\.openAIAPISecretKey, Defaults[.openAIAPIKey])
                .environment(\.openAIAPIURL, Defaults[.openAIAPIURL])
                .environment(\.openAIAPIPrompt, Defaults[.openAIAPIPrompt])
                .environment(\.openAIAPIModel, Defaults[.openAIAPIModel])
                .environment(\.openAIAPIStagingPrompt, Defaults[.openAIAPIStagingPrompt])
        }
        Window("Commit Message Snippets", id: WindowID.commitMessageSnippets.rawValue) {
            CommitMessageSnippetView()
        }
    }
}
