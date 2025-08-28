//
//  GitRepoSettingsView.swift
//  GitClient
//
//  Created by Kiro on 2025/08/27.
//

import SwiftUI
import Foundation

struct GitRepoSettingsView: View {
    @AppStorage(AppStorageKey.gitRepoFolders.rawValue) private var gitRepoSettingsData: Data?
    @State private var gitRepoSettings = GitRepoSettings()
    @State private var foundRepos: [Folder] = []
    @State private var isScanning = false
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Git Repository Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Configure folders to scan for Git repositories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Search Folders Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Search Folders")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add Folder") {
                        addFolder()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Rescan") {
                        rescanRepositories()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    if gitRepoSettings.searchFolders.isEmpty {
                        Text("No folders added. Click 'Add Folder' to get started.")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(gitRepoSettings.searchFolders.enumerated()), id: \.offset) { index, folder in
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(.blue)
                                Text(folder.path)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Button("Remove") {
                                    removeFolder(at: index)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Scan Options Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Scan Options")
                    .font(.headline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-scan subfolders", isOn: $gitRepoSettings.autoScanSubfolders)
                        .onChange(of: gitRepoSettings.autoScanSubfolders) { _, _ in
                            saveSettings()
                        }
                    
                    if gitRepoSettings.autoScanSubfolders {
                        HStack {
                            Text("Max scan depth:")
                            Stepper(value: $gitRepoSettings.maxScanDepth, in: 1...10) {
                                Text("\(gitRepoSettings.maxScanDepth)")
                                    .font(.system(.body, design: .monospaced))
                            }
                            .onChange(of: gitRepoSettings.maxScanDepth) { _, _ in
                                saveSettings()
                            }
                        }
                        .padding(.leading, 20)
                    }
                    
                    Toggle("Auto-sort repositories", isOn: $gitRepoSettings.autoSort)
                        .help("Automatically sort repositories by name. When disabled, repositories are grouped by search folder.")
                        .onChange(of: gitRepoSettings.autoSort) { _, _ in
                            saveSettings()
                        }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Found Repositories Section
            if !foundRepos.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Found Repositories (\(foundRepos.count))")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(foundRepos, id: \.url) { repo in
                                HStack {
                                    Image(systemName: "folder.badge.gearshape")
                                        .foregroundColor(.green)
                                    Text(repo.displayName)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(repo.url.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxHeight: 400)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400)
        .onAppear {
            loadSettings()
            if !gitRepoSettings.searchFolders.isEmpty {
                rescanRepositories()
            }
        }
        .errorSheet($error)
    }
    
    private func loadSettings() {
        guard let data = gitRepoSettingsData else { return }
        do {
            gitRepoSettings = try JSONDecoder().decode(GitRepoSettings.self, from: data)
        } catch {
            self.error = error
        }
    }
    
    private func saveSettings() {
        do {
            gitRepoSettingsData = try JSONEncoder().encode(gitRepoSettings)
        } catch {
            self.error = error
        }
    }
    
    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = true
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    if !gitRepoSettings.searchFolders.contains(url) {
                        gitRepoSettings.searchFolders.append(url)
                    }
                }
                saveSettings()
                rescanRepositories()
            }
        }
    }
    
    private func removeFolder(at index: Int) {
        gitRepoSettings.searchFolders.remove(at: index)
        saveSettings()
        rescanRepositories()
    }
    
    private func rescanRepositories() {
        isScanning = true
        Task {
            let repos = GitRepoSettings.findGitRepositories(
                in: gitRepoSettings.searchFolders,
                autoScanSubfolders: gitRepoSettings.autoScanSubfolders,
                maxDepth: gitRepoSettings.maxScanDepth,
                autoSort: gitRepoSettings.autoSort
            )
            
            await MainActor.run {
                foundRepos = repos
                isScanning = false
            }
        }
    }
}

#Preview {
    GitRepoSettingsView()
}