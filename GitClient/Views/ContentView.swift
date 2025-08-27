//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings: OpenSettingsAction
    @AppStorage(AppStorageKey.folder.rawValue) var folders: Data?
    @AppStorage(AppStorageKey.gitRepoFolders.rawValue) private var gitRepoSettingsData: Data?
    @AppStorage(AppStorageKey.terminalSettings.rawValue) private var terminalSettingsData: Data?
    
    private var decodedFolders: [Folder] {
        var allFolders = getManualFolders()
        let discoveredFolders = getDiscoveredFolders()
        
        // Merge and remove duplicates
        for discoveredFolder in discoveredFolders {
            let folderExists = allFolders.contains { existingFolder in
                existingFolder.url == discoveredFolder.url
            }
            if !folderExists {
                allFolders.append(discoveredFolder)
            }
        }
        
        return allFolders.sorted { $0.displayName < $1.displayName }
    }
    
    private func getManualFolders() -> [Folder] {
        guard let folders = folders else { return [] }
        do {
            return try JSONDecoder().decode([Folder].self, from: folders)
        } catch {
            return []
        }
    }
    
    private func getDiscoveredFolders() -> [Folder] {
        guard let settingsData = gitRepoSettingsData else { return [] }
        do {
            let settings = try JSONDecoder().decode(GitRepoSettings.self, from: settingsData)
            return GitRepoSettings.findGitRepositories(
                in: settings.searchFolders,
                autoScanSubfolders: settings.autoScanSubfolders,
                maxDepth: settings.maxScanDepth
            )
        } catch {
            return []
        }
    }
    @State private var selectionFolderURL: URL?
    private var selectionFolder: Folder? {
        guard let selectionFolderURL = selectionFolderURL else { return nil}
        return decodedFolders.first(where: { $0.url == selectionFolderURL })
    }
    @State private var selectionLog: Log?
    @State private var subSelectionLogID: String?
    @State private var folderIsRefresh = false
    @State private var error: Error?
    @State private var isTargeted = false
    @State private var terminalSettings = TerminalSettings()


    var body: some View {
        NavigationSplitView {
            VStack {
                if decodedFolders.isEmpty {
                    VStack {
                        Text("No Project Folder Added")
                        Text("Please add a folder that contains a Git repository.")
                            .font(.caption)
                            .padding(.top, 2)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                } else {
                    List(decodedFolders, id: \.url, selection: $selectionFolderURL) { folder in
                        HStack {
                            Label(folder.displayName, systemImage: "folder")
                                .help(folder.url.path)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button {
                                    NSWorkspace.shared.open(folder.url)
                                } label: {
                                    Image(systemName: "folder")
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.plain)
                                .help("Open in Finder")
                                
                                Button {
                                    openInBrowser(folder: folder)
                                } label: {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .help("Open in Browser")
                                
                                Button {
                                    openInTerminal(folder: folder)
                                } label: {
                                    Image(systemName: "terminal")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                                .help("Open in Terminal")
                            }
                            .opacity(selectionFolderURL == folder.url ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.2), value: selectionFolderURL)
                        }
                        .contextMenu {
                            Button("Open in Browser") {
                                openInBrowser(folder: folder)
                            }
                            Button("Open in Terminal") {
                                openInTerminal(folder: folder)
                            }
                            Divider()
                            Button("Remove from List") {
                                removeFolder(folder)
                            }
                            Divider()
                            Button("Show in Finder") {
                                NSWorkspace.shared.open(folder.url)
                            }
                        }
                    }
                    .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers: providers)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                            .animation(.easeInOut(duration: 0.2), value: isTargeted)
                    )
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        addFolder()
                    } label: {
                        Image(systemName: "plus.rectangle.on.folder")
                    }
                    .help("Add Project Folder")
                    
                    Button {
                        rescanFolders()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Rescan for Git Repositories")
                    
                    Button {
                        openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("Settings")
                }
            }

        } content: {
            if let folder = selectionFolder {
                FolderView(
                    folder: folder,
                    selectionLog: $selectionLog,
                    subSelectionLogID: $subSelectionLogID,
                    isRefresh: $folderIsRefresh
                )
                .id(folder)
            } else {
                Text("No Folder Selection")
                    .foregroundColor(.secondary)
            }
        } detail: {
            if let selectionLog, let subSelectionLogID {
                CommitDiffView(selectionLogID: selectionLog.id, subSelectionLogID: subSelectionLogID)
            } else if let selectionFolder {
                switch selectionLog {
                case .notCommitted:
                    CommitCreateView(
                        folder: selectionFolder,
                        isRefresh: $folderIsRefresh,
                        onCommit: {
                            self.selectionLog = nil
                            folderIsRefresh = true
                        },
                        onStash: {
                            self.selectionLog = nil
                            folderIsRefresh = true
                        }
                    )
                case .committed(let commit):
                    CommitDetailStackView(commit: commit, folder: selectionFolder)
                case nil:
                    Text("No Selection")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 300)
        .onChange(of: selectionFolder, {
            selectionLog = nil
        })
        .errorSheet($error)
        .environment(\.folder, selectionFolderURL)
        .onAppear {
            loadTerminalSettings()
        }
        .onChange(of: terminalSettingsData) { _ in
            loadTerminalSettings()
        }

    }
    
    // MARK: - Helper Methods
    
    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = true
        panel.begin { response in
            if response == .OK {
                Task { @MainActor in
                    for fileURL in panel.urls {
                        addFolderToList(fileURL)
                    }
                }
            }
        }
    }
    
    private func addFolderToList(_ url: URL) {
        let chooseFolder = Folder(url: url)
        var currentFolders = getCurrentManualFolders()
        
        // Remove if already exists and add to front
        currentFolders.removeAll { $0 == chooseFolder }
        currentFolders.insert(chooseFolder, at: 0)
        
        do {
            try self.folders = JSONEncoder().encode(currentFolders)
        } catch {
            self.error = error
        }
    }
    
    private func removeFolder(_ folder: Folder) {
        var currentFolders = getCurrentManualFolders()
        currentFolders.removeAll { $0 == folder }
        
        do {
            try self.folders = JSONEncoder().encode(currentFolders)
        } catch {
            self.error = error
        }
    }
    
    private func getCurrentManualFolders() -> [Folder] {
        guard let folders = folders else { return [] }
        do {
            return try JSONDecoder().decode([Folder].self, from: folders)
        } catch {
            return []
        }
    }
    
    private func rescanFolders() {
        // Trigger a refresh by updating the gitRepoSettingsData
        // This will cause decodedFolders to recompute
        if let settingsData = gitRepoSettingsData {
            // Force a refresh by temporarily setting to nil and back
            let temp = gitRepoSettingsData
            gitRepoSettingsData = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                gitRepoSettingsData = temp
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        
                        var isDirectory: ObjCBool = false
                        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                           isDirectory.boolValue {
                            
                            DispatchQueue.main.async {
                                addFolderToList(url)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func loadTerminalSettings() {
        if let data = terminalSettingsData {
            do {
                terminalSettings = try JSONDecoder().decode(TerminalSettings.self, from: data)
            } catch {
                // Use default settings if decoding fails
                terminalSettings = TerminalSettings()
            }
        } else {
            // No settings saved yet, use default
            terminalSettings = TerminalSettings()
        }
    }
    
    private func openInBrowser(folder: Folder) {
        // Check if there's a remote URL in git config
        let gitConfigURL = folder.url.appendingPathComponent(".git/config")
        
        if FileManager.default.fileExists(atPath: gitConfigURL.path) {
            do {
                let gitConfig = try String(contentsOf: gitConfigURL)
                
                // Look for remote origin URL
                let lines = gitConfig.components(separatedBy: .newlines)
                var inOriginSection = false
                
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    
                    if trimmedLine == "[remote \"origin\"]" {
                        inOriginSection = true
                        continue
                    }
                    
                    if trimmedLine.hasPrefix("[") && trimmedLine != "[remote \"origin\"]" {
                        inOriginSection = false
                        continue
                    }
                    
                    if inOriginSection && trimmedLine.hasPrefix("url = ") {
                        let urlString = String(trimmedLine.dropFirst(6))
                        
                        // Convert SSH URLs to HTTPS
                        var webURL = urlString
                        if webURL.hasPrefix("git@github.com:") {
                            webURL = webURL.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                        } else if webURL.hasPrefix("git@gitlab.com:") {
                            webURL = webURL.replacingOccurrences(of: "git@gitlab.com:", with: "https://gitlab.com/")
                        } else if webURL.hasPrefix("git@bitbucket.org:") {
                            webURL = webURL.replacingOccurrences(of: "git@bitbucket.org:", with: "https://bitbucket.org/")
                        }
                        
                        // Remove .git suffix
                        if webURL.hasSuffix(".git") {
                            webURL = String(webURL.dropLast(4))
                        }
                        
                        if let url = URL(string: webURL) {
                            NSWorkspace.shared.open(url)
                            return
                        }
                    }
                }
            } catch {
                // If we can't read git config, fall back to opening the folder
            }
        }
        
        // Fallback: open the folder in Finder
        NSWorkspace.shared.open(folder.url)
    }
    
    private func openInTerminal(folder: Folder) {
        if let selectedTerminal = terminalSettings.selectedTerminal {
            let customArguments = terminalSettings.customArguments(for: selectedTerminal.bundleIdentifier)
            selectedTerminal.openTerminal(at: folder.url, customArguments: customArguments)
        } else {
            // Fallback to default Terminal.app
            let defaultTerminal = TerminalApp.availableTerminals.first { $0.bundleIdentifier == "com.apple.Terminal" }
            defaultTerminal?.openTerminal(at: folder.url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
