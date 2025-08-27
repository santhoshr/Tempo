//
//  GitRepoSettings.swift
//  GitClient
//
//  Created by Kiro on 2025/08/27.
//

import Foundation

struct GitRepoSettings: Codable {
    var searchFolders: [URL]
    var autoScanSubfolders: Bool
    var maxScanDepth: Int
    
    init() {
        self.searchFolders = []
        self.autoScanSubfolders = true
        self.maxScanDepth = 3
    }
}

extension GitRepoSettings {
    static func findGitRepositories(in folders: [URL], autoScanSubfolders: Bool, maxDepth: Int) -> [Folder] {
        var gitRepos: [Folder] = []
        
        for folder in folders {
            if autoScanSubfolders {
                gitRepos.append(contentsOf: scanForGitRepos(in: folder, currentDepth: 0, maxDepth: maxDepth))
            } else {
                // Only check the folder itself
                if isGitRepository(folder) {
                    gitRepos.append(Folder(url: folder))
                }
            }
        }
        
        // Remove duplicates and sort
        let uniqueRepos = Array(Set(gitRepos)).sorted { $0.displayName < $1.displayName }
        return uniqueRepos
    }
    
    private static func scanForGitRepos(in folder: URL, currentDepth: Int, maxDepth: Int) -> [Folder] {
        guard currentDepth <= maxDepth else { return [] }
        
        var repos: [Folder] = []
        
        // Check if current folder is a git repo
        if isGitRepository(folder) {
            repos.append(Folder(url: folder))
            return repos // Don't scan subfolders of git repos
        }
        
        // Scan subfolders
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            for item in contents {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory),
                   isDirectory.boolValue {
                    repos.append(contentsOf: scanForGitRepos(in: item, currentDepth: currentDepth + 1, maxDepth: maxDepth))
                }
            }
        } catch {
            // Ignore errors and continue
        }
        
        return repos
    }
    
    private static func isGitRepository(_ url: URL) -> Bool {
        let gitPath = url.appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitPath.path)
    }
}