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
        
        let windowController = NSWindowController(window: NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        ))
        
        windowController.window?.center()
        windowController.window?.setFrameAutosaveName("NotesToRepoWindow")
        windowController.window?.contentView = NSHostingView(
            rootView: NotesToSelfPopupView()
                .environment(\.folder, folderURL)
        )
        
        let folderName = folderURL.lastPathComponent
        windowController.window?.title = "Repository Notes - \(folderName)"
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }
}
