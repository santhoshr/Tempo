//
//  GitRepoSettings.swift
//  GitClient
//
//  Created by Kiro on 2025/08/27.
//

import Foundation

enum RepoSortOption: String, CaseIterable, Codable {
    case repoName = "repoName"
    case searchPath = "searchPath"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .repoName: return "Repo Name"
        case .searchPath: return "Search Path (Folder)"
        case .manual: return "Manual"
        }
    }
}

struct GitRepoSettings: Codable {
    var searchFolders: [URL]
    var autoScanSubfolders: Bool
    var maxScanDepth: Int
    var sortOption: RepoSortOption
    var manualOrder: [String] // Store repo paths for manual ordering
    
    init() {
        self.searchFolders = []
        self.autoScanSubfolders = true
        self.maxScanDepth = 3
        self.sortOption = .repoName
        self.manualOrder = []
    }
    
    // Custom decoding to handle legacy autoSort
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        searchFolders = try container.decode([URL].self, forKey: .searchFolders)
        autoScanSubfolders = try container.decode(Bool.self, forKey: .autoScanSubfolders)
        maxScanDepth = try container.decode(Int.self, forKey: .maxScanDepth)
        manualOrder = try container.decodeIfPresent([String].self, forKey: .manualOrder) ?? []
        
        // Handle legacy autoSort or new sortOption
        if let sortOption = try container.decodeIfPresent(RepoSortOption.self, forKey: .sortOption) {
            self.sortOption = sortOption
        } else if let legacyAutoSort = try container.decodeIfPresent(Bool.self, forKey: .legacyAutoSort) {
            self.sortOption = legacyAutoSort ? .repoName : .searchPath
        } else {
            self.sortOption = .repoName
        }
    }
    
    // Custom encoding to use new format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(searchFolders, forKey: .searchFolders)
        try container.encode(autoScanSubfolders, forKey: .autoScanSubfolders)
        try container.encode(maxScanDepth, forKey: .maxScanDepth)
        try container.encode(sortOption, forKey: .sortOption)
        try container.encode(manualOrder, forKey: .manualOrder)
    }
    
    private enum CodingKeys: String, CodingKey {
        case searchFolders, autoScanSubfolders, maxScanDepth, sortOption, manualOrder
        case legacyAutoSort = "autoSort"
    }
}

extension GitRepoSettings {
    static func findGitRepositories(in folders: [URL], autoScanSubfolders: Bool, maxDepth: Int, sortOption: RepoSortOption = .repoName, manualOrder: [String] = []) -> [Folder] {
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
        
        return sortRepositories(uniqueRepos, by: sortOption, searchFolders: folders, manualOrder: manualOrder)
    }
    
    // Legacy method for backward compatibility
    static func findGitRepositories(in folders: [URL], autoScanSubfolders: Bool, maxDepth: Int, autoSort: Bool = true) -> [Folder] {
        return findGitRepositories(in: folders, autoScanSubfolders: autoScanSubfolders, maxDepth: maxDepth, sortOption: autoSort ? .repoName : .searchPath)
    }
    
    private static func sortRepositories(_ repos: [Folder], by sortOption: RepoSortOption, searchFolders: [URL], manualOrder: [String]) -> [Folder] {
        switch sortOption {
        case .repoName:
            return repos.sorted { folder1, folder2 in
                let name1 = folder1.displayName
                let name2 = folder2.displayName
                if name1 == name2 {
                    // If names are the same, sort by full path to ensure stable ordering
                    return folder1.url.path.localizedCaseInsensitiveCompare(folder2.url.path) == .orderedAscending
                }
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
            
        case .searchPath:
            // Sort by path for stable, predictable ordering (like the old fixed sort)
            return repos.sorted { repo1, repo2 in
                let path1 = repo1.url.path
                let path2 = repo2.url.path
                
                // First compare by path depth (shallower paths first)
                let depth1 = path1.components(separatedBy: "/").count
                let depth2 = path2.components(separatedBy: "/").count
                
                if depth1 != depth2 {
                    return depth1 < depth2
                }
                
                // If same depth, sort alphabetically by full path
                return path1.localizedCaseInsensitiveCompare(path2) == .orderedAscending
            }
            
        case .manual:
            // Sort by manual order, putting unordered items at the end
            let orderedPaths = manualOrder
            var orderedRepos: [Folder] = []
            var remainingRepos = repos
            
            // Add repos in manual order
            for path in orderedPaths {
                if let index = remainingRepos.firstIndex(where: { $0.url.path == path }) {
                    orderedRepos.append(remainingRepos.remove(at: index))
                }
            }
            
            // Add remaining repos (not in manual order) at the end, sorted by name
            orderedRepos.append(contentsOf: remainingRepos.sorted { $0.displayName < $1.displayName })
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