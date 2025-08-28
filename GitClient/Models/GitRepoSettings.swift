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
    var autoSort: Bool
    
    init() {
        self.searchFolders = []
        self.autoScanSubfolders = true
        self.maxScanDepth = 3
        self.autoSort = true
    }
}

extension GitRepoSettings {
    static func findGitRepositories(in folders: [URL], autoScanSubfolders: Bool, maxDepth: Int, autoSort: Bool = true) -> [Folder] {
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
        
        // Remove duplicates
        let uniqueRepos = Array(Set(gitRepos))
        
        if autoSort {
            return uniqueRepos.sorted { $0.displayName < $1.displayName }
        } else {
            // Maintain order by search folder
            var orderedRepos: [Folder] = []
            for searchFolder in folders {
                let reposFromThisFolder = uniqueRepos.filter { repo in
                    repo.url.path.hasPrefix(searchFolder.path)
                }
                orderedRepos.append(contentsOf: reposFromThisFolder)
            }
            return orderedRepos
        }
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