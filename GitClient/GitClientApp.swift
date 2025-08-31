//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI
import Defaults
import AppKit

@main
struct GitClientApp: App {
    @State var expandAllFiles: UUID?
    @State var collapseAllFiles: UUID?
    @State var selectedFolder: URL?

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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FolderSelected"))) { notification in
                    if let folderURL = notification.object as? URL {
                        selectedFolder = folderURL
                    }
                }
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
            CommandGroup(after: .windowArrangement) {
                Button("Notes to Repo") {
                    openNotesToRepoWindow()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(selectedFolder == nil)
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
    
    private func openNotesToRepoWindow() {
        guard let folderURL = selectedFolder else { return }
        NotesToRepoWindowManager.openWindow(for: folderURL)
    }
}
