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
                    
                    HStack {
                        Text("Sort by:")
                        Picker("Sort by", selection: $gitRepoSettings.sortOption) {
                            ForEach(RepoSortOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: gitRepoSettings.sortOption) { _, newValue in
                            saveSettings()
                            if newValue != .manual {
                                rescanRepositories()
                            }
                        }
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
                        
                        if gitRepoSettings.sortOption == .manual {
                            Text("• Drag to reorder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        Spacer()
                        
                        if isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    List {
                        ForEach(foundRepos, id: \.url) { repo in
                            HStack(spacing: 12) {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundColor(.green)
                                    .frame(width: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(repo.displayName)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text(repo.url.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if gitRepoSettings.sortOption == .manual {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 16)
                                }
                            }
                            .padding(.vertical, gitRepoSettings.sortOption == .manual ? 8 : 6)
                            .padding(.horizontal, 8)
                            .background(gitRepoSettings.sortOption == .manual ? Color(NSColor.controlBackgroundColor).opacity(0.3) : Color.clear)
                            .cornerRadius(gitRepoSettings.sortOption == .manual ? 4 : 0)
                            .contentShape(Rectangle())
                        }
                        .onMove(perform: gitRepoSettings.sortOption == .manual ? moveRepos : nil)
                        .moveDisabled(gitRepoSettings.sortOption != .manual)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(minHeight: 200, idealHeight: 300, maxHeight: 400)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .clipped()
                }
            }
            
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 600)
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
                sortOption: gitRepoSettings.sortOption,
                manualOrder: gitRepoSettings.manualOrder
            )
            
            await MainActor.run {
                foundRepos = repos
                isScanning = false
            }
        }
    }
    
    private func moveRepos(from source: IndexSet, to destination: Int) {
        foundRepos.move(fromOffsets: source, toOffset: destination)
        
        // Update manual order
        gitRepoSettings.manualOrder = foundRepos.map { $0.url.path }
        saveSettings()
    }
}

#Preview {
    GitRepoSettingsView()
}